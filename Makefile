PORT ?= 8000
HOST ?= 0.0.0.0
PID_FILE := .server.pid
URL := http://localhost:$(PORT)/

IMAGE ?= parking-jam
TAG ?= latest
DOCKER_PORT ?= 8080

.PHONY: help serve start stop restart open lan bump clean \
        docker-build docker-run docker-stop docker-push docker-shell \
        publish

help:
	@echo "Targets:"
	@echo "  serve    - run server in foreground (Ctrl+C to stop)"
	@echo "  start    - run server in background (PORT=$(PORT))"
	@echo "  stop     - stop the background server"
	@echo "  restart  - stop then start"
	@echo "  open     - open $(URL) in default browser"
	@echo "  lan      - print LAN URL for testing on phones"
	@echo "  bump     - bump service worker cache version"
	@echo "  clean    - remove pid file and macOS junk"
	@echo ""
	@echo "Docker:"
	@echo "  docker-build  - build $(IMAGE):$(TAG)"
	@echo "  docker-run    - build + run on host port $(DOCKER_PORT)"
	@echo "  docker-stop   - stop and remove the container"
	@echo "  docker-push   - push $(IMAGE):$(TAG)"
	@echo ""
	@echo "Deploy:"
	@echo "  publish  - merge main into gh-pages and push to GitHub"

serve:
	python3 -m http.server $(PORT) --bind $(HOST)

start: stop
	@nohup python3 -m http.server $(PORT) --bind $(HOST) > /dev/null 2>&1 & echo $$! > $(PID_FILE)
	@sleep 0.3
	@echo "serving on $(URL) (pid $$(cat $(PID_FILE)))"

stop:
	@if [ -f $(PID_FILE) ]; then \
	  kill $$(cat $(PID_FILE)) 2>/dev/null || true; \
	  rm -f $(PID_FILE); \
	  echo "stopped"; \
	else \
	  pkill -f "http.server $(PORT)" 2>/dev/null && echo "stopped (by pattern)" || echo "not running"; \
	fi

restart: stop start

open:
	@open $(URL)

lan:
	@ip=$$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null); \
	echo "LAN URL: http://$$ip:$(PORT)/"

bump:
	@cur=$$(grep -Eo "parking-jam-v[0-9]+" sw.js | head -1); \
	n=$$(echo $$cur | grep -Eo "[0-9]+$$"); \
	new=$$((n + 1)); \
	sed -i '' "s/parking-jam-v$$n/parking-jam-v$$new/" sw.js; \
	echo "sw.js: $$cur -> parking-jam-v$$new"

clean:
	@rm -f $(PID_FILE)
	@find . -name ".DS_Store" -delete
	@echo "cleaned"

docker-build:
	docker build -t $(IMAGE):$(TAG) .

docker-run: docker-build
	@docker rm -f $(IMAGE) 2>/dev/null || true
	docker run -d --name $(IMAGE) -p $(DOCKER_PORT):80 $(IMAGE):$(TAG)
	@echo "running at http://localhost:$(DOCKER_PORT)/"

docker-stop:
	@docker rm -f $(IMAGE) 2>/dev/null && echo "stopped" || echo "not running"

docker-shell:
	docker run --rm -it -p $(DOCKER_PORT):80 $(IMAGE):$(TAG) sh

docker-push:
	docker push $(IMAGE):$(TAG)

publish:
	@git checkout gh-pages
	@git merge main --no-edit
	@git push github gh-pages
	@git checkout main
	@echo "published to https://xuwang.github.io/parking-jam/"
