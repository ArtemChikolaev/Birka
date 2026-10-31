# One entry point for local work and CI. Run `make` to list the targets.
.DEFAULT_GOAL := help

# Pure-Dart packages that must behave the same on the VM, dart2js and dart2wasm.
CORE_PACKAGES := packages/core/money packages/core/l10n packages/core/ledger \
	packages/features/accounts/common packages/features/categories/common \
	packages/features/overview/common packages/features/reports/common \
	packages/features/transactions/common

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

# Where the site lives: / locally and /Birka/ on GitHub Pages.
BASE ?= /

# The build number of the APK: CI passes the number of its run.
BUILD_NUMBER ?= 1

.PHONY: help bootstrap format analyze check-deps check-tokens tokens gen icons \
	icon-masters web-fonts test test-core test-database test-tools test-design \
	test-features test-web test-mobile run-mobile run-web build-web build-apk check

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

gen: ## Generate the strings, the Drift code and the snapshot of the schema
	cd packages/core/l10n && dart run slang
	cd packages/core/database && \
		dart run build_runner build --delete-conflicting-outputs && \
		dart run drift_dev make-migrations

tokens: ## Regenerate the Dart and CSS design tokens
	cd packages/design/tokens && dart run design_tokens:generate

icon-masters: ## Render the icon masters from coin.svg (needs Chrome)
	tools/dev/render_icons.sh

icons: ## App icons and launch screens from the masters (macOS)
	tools/dev/apply_icons.sh

web-fonts: ## WOFF2 subsets for the web from the Flutter kit's fonts
	tools/dev/build_web_fonts.sh

test: test-core test-database test-tools test-design test-features test-web test-mobile ## All tests on the VM

test-core: ## Core tests; COMPILER=vm|dart2js|dart2wasm
	@for package in $(CORE_PACKAGES); do \
		echo "== $$package ($(COMPILER))"; \
		(cd $$package && dart test $(TEST_FLAGS)) || exit 1; \
	done

test-database: ## Tests of the schema, on the VM only
	cd packages/core/database && dart test

test-tools: ## Tests of the repository tooling
	cd tools && dart test

test-design: ## Tests of the token generator and both kits
	cd packages/design/tokens && dart test
	cd packages/design/flutter && flutter test
	cd packages/design/jaspr && dart test

test-features: ## Tests of the screens of the features
	cd packages/features/accounts/flutter && flutter test
	cd packages/features/accounts/jaspr && dart test
	cd packages/features/categories/flutter && flutter test
	cd packages/features/categories/jaspr && dart test
	cd packages/features/overview/flutter && flutter test
	cd packages/features/reports/flutter && flutter test
	cd packages/features/transactions/flutter && flutter test

test-web: ## Tests of the Jaspr host
	cd apps/web && dart test

test-mobile: ## Widget tests of the Flutter host
	cd apps/mobile && flutter test

run-mobile: ## Run the Flutter host; DEVICE=macos|iPhone|emulator
	cd apps/mobile && flutter run -d $(DEVICE)

run-web: ## Serve the site on localhost:8080, rebuilt on every change
	# In release mode, because the worker of Drift cannot run as DDC modules.
	cd apps/web && dart run jaspr_cli:jaspr serve --release

build-web: ## The static site in apps/web/build/jaspr; BASE=/Birka/ as on Pages
	cd apps/web && dart run jaspr_cli:jaspr build --dart-define=BASE_PATH=$(BASE)
	# The build copies the assets of every package; the site needs only these.
	find apps/web/build/jaspr/packages -mindepth 1 -maxdepth 1 \
		! -name 'design_*' -exec rm -rf {} +
	find apps/web/build/jaspr/packages -name '*.json' -delete
	rm -rf apps/web/build/jaspr/.dart_tool apps/web/build/jaspr/.build.manifest

build-apk: ## A release APK for arm64 in apps/mobile/build/app/outputs/flutter-apk
	cd apps/mobile && flutter build apk --release \
		--target-platform android-arm64 --build-number=$(BUILD_NUMBER)

check: analyze test ## What CI checks on every pull request (VM only)
