#  Makefile for performing various tasks.

SELF_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: compiler
compiler:
	@echo "Building the compiler..."
	@cd "$(SELF_DIR)../.."; ./gradlew :compiler:installDist
	@echo "Copying the compiler to native/ios/compiler/ ..."
	@rm -r "$(SELF_DIR)compiler/"; mkdir compiler
	@cp -r "$(SELF_DIR)../../compiler/build/install/compiler/." "$(SELF_DIR)/compiler/"
	@echo "Make compiler finished."

.PHONY: fdl-gen
fdl-gen:
	cd "$(SELF_DIR)/scripts"; ./fdl-gen.sh ../Tests/Fixtures/TestExample.fdl ../Tests/Fixtures/TestExample.generated.swift

.PHONY: template
template:
	open "$(SELF_DIR)/../../parser/src/main/resources/SwiftClient.mustache"

.PHONY: lint
lint:
	swiftlint --fix --config ./.swiftlint.yml

.PHONY: open
open:
	open ./CausalLabsSDK.xcodeproj

.PHONY: example
example:
	open ./Example/ExampleApp.xcodeproj

.PHONY: test
test:
	./scripts/test.sh

.PHONY: docs
docs:
	./scripts/docs.zsh
