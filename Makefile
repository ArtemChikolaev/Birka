# One entry point for local work and CI. Run `make` to list the targets.
.DEFAULT_GOAL := help

# Pure-Dart packages that must behave the same on the VM, dart2js and dart2wasm.
CORE_PACKAGES := packages/core/money

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

# Device for run-mobile: macos, or the start of a device name such as iPhone
# or emulator (`flutter devices` lists them).
DEVICE ?= macos

.PHONY: help bootstrap format analyze check-deps check-tokens tokens icons \
	icon-masters test test-core test-tools test-design test-mobile run-mobile \
	check

help: ## Show the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-12s %s\n", $$1, $$2}'

bootstrap: ## Fetch dependencies for the whole workspace
	flutter pub get

format: ## Format all Dart code
	dart format .

analyze: ## Formatting, analysis, package boundaries, generated tokens
	dart format --output=none --set-exit-if-changed .
	dart analyze --fatal-infos
	$(MAKE) check-deps
	$(MAKE) check-tokens

check-deps: ## Package boundary rules from ADR 0001
	dart run birka_tools:check_deps

check-tokens: ## Generated tokens match their sources (ADR 0007)
	cd packages/design/tokens && dart run design_tokens:generate --check

tokens: ## Regenerate the Dart and CSS design tokens
	cd packages/design/tokens && dart run design_tokens:generate

icon-masters: ## Render the icon masters from coin.svg (needs Chrome)
	tools/dev/render_icons.sh

icons: ## App icons and launch screens from the masters (macOS)
	tools/dev/apply_icons.sh

test: test-core test-tools test-design test-mobile ## All tests on the Dart VM

test-core: ## Core tests; COMPILER=vm|dart2js|dart2wasm
	@for package in $(CORE_PACKAGES); do \
		echo "== $$package ($(COMPILER))"; \
		(cd $$package && dart test $(TEST_FLAGS)) || exit 1; \
	done

test-tools: ## Tests of the repository tooling
	cd tools && dart test

test-design: ## Tests of the token generator and the Flutter kit
	cd packages/design/tokens && dart test
	cd packages/design/flutter && flutter test

test-mobile: ## Widget tests of the Flutter host
	cd apps/mobile && flutter test

run-mobile: ## Run the Flutter host; DEVICE=macos|iPhone|emulator
	cd apps/mobile && flutter run -d $(DEVICE)

check: analyze test ## What CI checks on every pull request (VM only)
