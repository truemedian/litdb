APP_FILES=$(shell find lib tests -type f -name '*.lua')

all: lit $(APP_FILES)

test: lit
	./lit install
	LUVI_APP=. LUVI_MAIN=tests/run.lua ./lit

lit:
	curl -L https://github.com/luvit/lit/raw/1.0.2/get-lit.sh | sh

lint: $(APP_FILES)
	find lib tests -name "*.lua" | xargs luacheck

.PHONY: clean lint
