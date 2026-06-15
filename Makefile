.PHONY: build test run clean deploy

build:
	podman-compose build

test:
	podman-compose run --rm app pytest tests/ -v

run:
	podman-compose up -d

clean:
	podman-compose down -v
	podman system prune -f

deploy:
	# Остановка старого контейнера
	-podman stop app-$(USER) || true
	-podman rm app-$(USER) || true
	# Запуск нового
	podman run -d \
		--name app-$(USER) \
		-p $(PORT):8048 \
		-e DB_HOST=$(DB_HOST) \
		-e DB_PORT=$(DB_PORT) \
		-e DB_USER=$(DB_USER) \
		-e DB_PASSWORD=$(DB_PASSWORD) \
		-e DB_NAME=$(DB_NAME) \
		$(IMAGE_NAME):latest
