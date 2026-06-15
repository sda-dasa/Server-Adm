# Stage 1: Builder
FROM python:3.11-slim as builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml ./
COPY src/ ./src/

# Устанавливаем в стандартную системную директорию
RUN pip install --no-cache-dir .[test]

# Stage 2: Runtime
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Копируем установленные пакеты из системной директории builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Копируем исходный код
COPY src/ ./src/
COPY tests/ ./tests/

# Не создаем отдельного пользователя для простоты
# (в production можно добавить, но для CI/CD пока убираем)

EXPOSE 8048

# Убеждаемся, что pytest доступен
RUN which pytest || echo "pytest not found" && ls -la /usr/local/bin/

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8048"]
