# Stage 1: Builder
FROM python:3.11-slim AS builder

WORKDIR /app

# Установка build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Копируем зависимости
COPY pyproject.toml ./

# Создаем virtualenv
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Устанавливаем зависимости в virtualenv
RUN pip install --no-cache-dir .[test]

# Stage 2: Runtime
FROM python:3.11-slim AS runtime

WORKDIR /app

# Runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Копируем virtualenv из builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Копируем код
COPY src/ ./src/
COPY tests/ ./tests/

# Проверяем доступность pytest
RUN python -c "import pytest; print(f'pytest version: {pytest.__version__}')"

EXPOSE 8048

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8048/health || exit 1

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8048"]
