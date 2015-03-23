APP_FILES=$(shell find . -type f -name '*.lua')

all: lit

test: lit
	./lit install
	LUVI_APP=. LUVI_MAIN=tests/run.lua ./lit

lit:
	curl -L https://github.com/luvit/lit/raw/1.0.2/get-lit.sh | sh

lint:
	find . -name "*.lua" | xargs luacheck

.PHONY: clean lint
