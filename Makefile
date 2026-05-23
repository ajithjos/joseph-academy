.PHONY:

RUST_CLI_INSTALL_ROOT ?= $(CURDIR)/scratchpad/dev/local/runtime/rust-cli
RUST_DENY_TARGETS ?= --target aarch64-apple-darwin --target x86_64-unknown-linux-gnu
FLUTTER_VERIFINDER_DIR ?= $(CURDIR)/fe/flutter/apps/verifinder
FLUTTER_REQUIRED_VERSION ?= 3.41.9
ARGS ?=
PYTHON_RUN ?= uv run
