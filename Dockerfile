FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml ./

RUN pip install --no-cache-dir --break-system-packages .[test]

RUN python -c "import psycopg; print(f'✅ psycopg version: {psycopg.__version__}')"
RUN python -c "import uvicorn; print(f'✅ uvicorn version: {uvicorn.__version__}')"

COPY src/ ./src/
COPY tests/ ./tests/

EXPOSE 8048

CMD ["python", "-m", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8048"]
