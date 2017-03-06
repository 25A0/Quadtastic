TESTS := $(shell find tests -type f -name "test_*.lua")

.PHONY: test tests/*

all: test
	love src

test: ${TESTS}

tests/test_*.lua:
	lua $@
