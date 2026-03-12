.PHONY: install run kill clean

PORT := 3456
LOG_FILE := dev.log

install:
	npm install

kill:
	@-fuser -k $(PORT)/tcp 2>/dev/null || true
	@echo "Killed any process on port $(PORT)"

run: kill
	npm run dev 2>&1 | tee $(LOG_FILE)

run-bg: kill
	npm run dev > $(LOG_FILE) 2>&1 &
	@echo "Server started in background. Logs: $(LOG_FILE)"

logs:
	tail -f $(LOG_FILE)

build:
	npm run build

lint:
	npm run lint

clean:
	rm -f $(LOG_FILE)

# Production mode (no HMR, better for remote access)
start: kill build
	npm run start 2>&1 | tee $(LOG_FILE)

# Database inspection
messages:
	@node scripts/show-messages.mjs --all

sessions:
	@node scripts/show-messages.mjs --sessions

roundtables:
	@node scripts/show-messages.mjs --roundtables
