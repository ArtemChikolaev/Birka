# One entry point for local work and CI. Run `make` to list the targets.
.DEFAULT_GOAL := help

# Pure-Dart packages that must behave the same on the VM, dart2js and dart2wasm.
CORE_PACKAGES := packages/money

COMPILER ?= vm
ifeq ($(COMPILER),vm)
  TEST_FLAGS :=
else ifeq ($(COMPILER),dart2js)
  TEST_FLAGS := --platform chrome --compiler dart2js
else ifeq ($(COMPILER),dart2wasm)
  TEST_FLAGS := --platform chrome --compiler dart2wasm
else
  $(error COMPILER must be vm, dart2js or dart2wasm)
endif

.PHONY: help bootstrap format analyze check-deps test test-core test-tools check

help: ## Show the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-12s %s\n", $$1, $$2}'

bootstrap: ## Fetch dependencies for the whole workspace
	flutter pub get

format: ## Format all Dart code
	dart format .

analyze: ## Formatting, static analysis and package boundaries
	dart format --output=none --set-exit-if-changed .
	dart analyze --fatal-infos
	$(MAKE) check-deps

check-deps: ## Package boundary rules from ADR 0001
	dart run birka_tools:check_deps

test: test-core test-tools ## All tests on the Dart VM

test-core: ## Core tests; COMPILER=vm|dart2js|dart2wasm
	@for package in $(CORE_PACKAGES); do \
		echo "== $$package ($(COMPILER))"; \
		(cd $$package && dart test $(TEST_FLAGS)) || exit 1; \
	done

test-tools: ## Tests of the repository tooling
	cd tools && dart test

check: analyze test ## What CI checks on every pull request (VM only)
