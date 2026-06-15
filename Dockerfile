# Stage 1: Builder
FROM python:3.11-slim as builder

WORKDIR /app

# Устанавливаем системные зависимости для компиляции
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Копируем только файлы с зависимостями
COPY pyproject.toml ./
COPY src/ ./src/

# Устанавливаем зависимости в отдельную директорию
RUN pip install --user --no-cache-dir .[test]

# Stage 2: Runtime
FROM python:3.11-slim

WORKDIR /app

# Устанавливаем только runtime зависимости
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Копируем установленные пакеты из builder
COPY --from=builder /root/.local /root/.local

# Копируем исходный код
COPY src/ ./src/
COPY tests/ ./tests/

# Добавляем пользовательский bin в PATH
ENV PATH=/root/.local/bin:$PATH

# Создаем непривилегированного пользователя
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8048/health')" || exit 1

EXPOSE 8048

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8048"]
