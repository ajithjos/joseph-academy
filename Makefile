.PHONY: help install-dev fmt fmt-check lint test rust-fmt rust-lint rust-test rust-run rust-migrate rust-bootstrap-apply rust-catalog-validate frontend-pub-get flutter-version-check flutter-analyze flutter-test frontend-sanity docs-site-install docs-site-prepare docs-site-build docs-site-dev control-plane-db-up control-plane-db-migrate control-plane-bootstrap-apply control-plane-catalog-reload control-plane-compose-up control-plane-compose-down control-plane-compose-reset daily-local daily

PYTHON_RUN ?= uv run
FLUTTER_APP_DIR ?= $(CURDIR)/fe/flutter/apps/joseph_academy
DOCS_SITE_DIR ?= $(CURDIR)/docs_site
RUST_MANIFEST ?= $(CURDIR)/rust/Cargo.toml
FLUTTER_REQUIRED_VERSION ?= 3.41.9

help:
	@echo "Primary targets: daily-local, control-plane-compose-up, rust-run"
	@echo "Validation targets: fmt-check, lint, test, frontend-sanity, docs-site-build"
	@echo "Control-plane targets: control-plane-db-up, control-plane-db-migrate, control-plane-bootstrap-apply, control-plane-catalog-reload, control-plane-compose-up, control-plane-compose-down, control-plane-compose-reset"

install-dev:
	uv sync --all-extras

fmt:
	cargo fmt --manifest-path $(RUST_MANIFEST) --all
	@bash -lc 'cd "$(FLUTTER_APP_DIR)" && dart format lib test'
	$(PYTHON_RUN) ruff format scripts tests

fmt-check:
	cargo fmt --manifest-path $(RUST_MANIFEST) --all --check
	@bash -lc 'cd "$(FLUTTER_APP_DIR)" && dart format lib test --set-exit-if-changed'
	$(PYTHON_RUN) ruff format scripts tests --check

lint:
	cargo clippy --manifest-path $(RUST_MANIFEST) --workspace --all-targets --all-features -- -D warnings
	$(PYTHON_RUN) ruff check scripts tests

test:
	cargo test --manifest-path $(RUST_MANIFEST) --workspace --all-features
	@bash -lc 'cd "$(FLUTTER_APP_DIR)" && flutter test'
	$(PYTHON_RUN) pytest -q

rust-fmt:
	cargo fmt --manifest-path $(RUST_MANIFEST) --all

rust-lint:
	cargo clippy --manifest-path $(RUST_MANIFEST) --workspace --all-targets --all-features -- -D warnings

rust-test:
	cargo test --manifest-path $(RUST_MANIFEST) --workspace --all-features

rust-run:
	cargo run --manifest-path rust/apps/ja_control_plane/Cargo.toml -- server

rust-migrate:
	cargo run --manifest-path rust/apps/ja_control_plane/Cargo.toml -- migrate

rust-bootstrap-apply:
	cargo run --manifest-path rust/apps/ja_control_plane/Cargo.toml -- bootstrap-apply

rust-catalog-validate:
	cargo run --manifest-path rust/apps/ja_control_plane/Cargo.toml -- catalog-validate

frontend-pub-get:
	@bash -lc 'cd "$(FLUTTER_APP_DIR)" && flutter pub get'

flutter-version-check:
	@bash -lc 'required="$(FLUTTER_REQUIRED_VERSION)"; current="$$(flutter --version | head -n 1 | awk "{print \$$2}")"; [ "$$current" = "$$required" ] || { echo "Expected Flutter $$required but found $$current"; exit 1; }'

flutter-analyze: frontend-pub-get flutter-version-check
	@bash -lc 'cd "$(FLUTTER_APP_DIR)" && flutter analyze'

flutter-test: frontend-pub-get flutter-version-check
	@bash -lc 'cd "$(FLUTTER_APP_DIR)" && flutter test'

frontend-sanity: flutter-analyze flutter-test

docs-site-install:
	@bash -lc 'cd "$(DOCS_SITE_DIR)" && npm install'

docs-site-prepare:
	$(PYTHON_RUN) python scripts/render_catalog_docs.py

docs-site-build: docs-site-prepare
	@bash -lc 'cd "$(DOCS_SITE_DIR)" && npm install && npm run build'

docs-site-dev: docs-site-prepare
	@bash -lc 'cd "$(DOCS_SITE_DIR)" && npm install && npm run start -- --host 0.0.0.0 --port 3001'

control-plane-db-up:
	bash deploy/dev/setup.sh --postgres-only

control-plane-db-migrate:
	cargo run --manifest-path rust/apps/ja_control_plane/Cargo.toml -- migrate

control-plane-bootstrap-apply:
	cargo run --manifest-path rust/apps/ja_control_plane/Cargo.toml -- bootstrap-apply

control-plane-catalog-reload:
	cargo run --manifest-path rust/apps/ja_control_plane/Cargo.toml -- catalog-validate

control-plane-compose-up:
	bash deploy/dev/setup.sh

control-plane-compose-down:
	bash deploy/dev/down.sh

control-plane-compose-reset:
	bash deploy/dev/reset.sh

daily-local: fmt-check lint rust-test frontend-sanity docs-site-build

daily: daily-local test
