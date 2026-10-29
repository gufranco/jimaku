SHELL := /bin/sh
PREFIX ?= $(HOME)/.local
SCRIPTS := bin/jimaku lib/*.sh scripts/*.sh test/*.sh test/*.bash test/*.bats

.PHONY: help fmt lint test test-all test-linux coverage check install

help:
	@echo "targets:"
	@echo "  fmt         format every script with shfmt -i 2"
	@echo "  lint        shfmt, shellcheck -o all and mandoc at zero findings"
	@echo "  test        bats suites under the system sh"
	@echo "  test-all    bats suites under every installed shell"
	@echo "  test-linux  the same suites in an Ubuntu container"
	@echo "  coverage    bashcov on this Mac and in the Ubuntu container, merged, gate 100%"
	@echo "  check       lint and test"
	@echo "  install     install the tool, man page and completions under PREFIX (default ~/.local)"

fmt:
	shfmt -i 2 -w $(SCRIPTS)

lint:
	shfmt -i 2 -d $(SCRIPTS)
	shellcheck -x -s sh -o all bin/jimaku lib/*.sh scripts/*.sh test/call.sh test/run-matrix.sh test/linux-container.sh
	sh scripts/check-names.sh
	shellcheck -x -o all test/*.bash test/*.bats
	shellcheck -s bash -o all completions/jimaku.bash
	mandoc -T lint man/jimaku.1

test:
	JIMAKU_TEST_SHELLS=sh sh test/run-matrix.sh

test-all:
	sh test/run-matrix.sh

test-linux:
	sh test/linux-container.sh sh test/run-matrix.sh

coverage:
	sh scripts/coverage.sh 0 && cp -f coverage/.resultset.json coverage-macos.json
	sh test/linux-container.sh sh scripts/linux-coverage.sh
	python3 scripts/coverage-gate.py '/(bin/jimaku|lib/[a-z]+\.sh)\Z' 100 coverage-macos.json coverage-linux.json

check: lint test

install:
	mkdir -p "$(PREFIX)/share/jimaku" "$(PREFIX)/bin" "$(PREFIX)/share/man/man1" "$(PREFIX)/share/bash-completion/completions" "$(PREFIX)/share/zsh/site-functions" "$(PREFIX)/share/fish/vendor_completions.d"
	cp -R bin lib "$(PREFIX)/share/jimaku/"
	cp -f man/jimaku.1 "$(PREFIX)/share/man/man1/jimaku.1"
	cp -f completions/jimaku.bash "$(PREFIX)/share/bash-completion/completions/jimaku"
	cp -f completions/_jimaku "$(PREFIX)/share/zsh/site-functions/_jimaku"
	cp -f completions/jimaku.fish "$(PREFIX)/share/fish/vendor_completions.d/jimaku.fish"
	printf '#!/bin/sh\nexec "%s/share/jimaku/bin/jimaku" "$$@"\n' "$(PREFIX)" > "$(PREFIX)/bin/jimaku"
	chmod 755 "$(PREFIX)/bin/jimaku"
