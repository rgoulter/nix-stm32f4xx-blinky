STM32F4_TARGET := thumbv7em-none-eabihf
STM32F4_TARGET_DIR := target/$(STM32F4_TARGET)
STM32F4_DEBUG_TARGET_DIR ?= $(STM32F4_TARGET_DIR)/debug
STM32F4_RELEASE_TARGET_DIR ?= $(STM32F4_TARGET_DIR)/release
BIN_NAME := rgoulter-stm32f401-blinky
DEST_DIR ?= .
STM32F4_BINARIES := $(notdir $(basename $(wildcard src/bin/*.rs))) $(BIN_NAME)
BINARIES := $(STM32F4_BINARIES)
BINARIES_BIN := $(addsuffix .bin,$(BINARIES))
BINARIES_UF2 := $(addsuffix .uf2,$(BINARIES))
STM32F4_EXAMPLES := $(notdir $(basename $(wildcard examples/*.rs)))
EXAMPLES := $(STM32F4_EXAMPLES)
EXAMPLES_BIN := $(addprefix example-, $(addsuffix .bin,$(EXAMPLES)))
EXAMPLES_UF2 := $(addprefix example-, $(addsuffix .uf2,$(EXAMPLES)))
TARGETS = $(BINARIES) $(EXAMPLES)
TARGETS_BIN = $(BINARIES_BIN) $(EXAMPLES_BIN)
TARGETS_UF2 = $(BINARIES_UF2) $(EXAMPLES_UF2)

.PHONY: all
all: targets.bin targets.uf2

.PHONY: clean
clean: clean.bin clean.uf2

.PHONY: clean.bin
clean.bin:
	rm -f $(addprefix $(DEST_DIR)/,$(TARGETS_BIN))

.PHONY: clean.uf2
clean.uf2:
	rm -f $(addprefix $(DEST_DIR)/,$(TARGETS_UF2))

.PHONY: targets.bin
targets.bin: $(addprefix $(DEST_DIR)/,$(TARGETS_BIN))

.PHONY: targets.uf2
targets.uf2: $(addprefix $(DEST_DIR)/,$(TARGETS_UF2))

$(STM32F4_DEBUG_TARGET_DIR)/examples/%: examples/%.rs
	cargo build --target=$(STM32F4_TARGET) --example="$*"

$(STM32F4_RELEASE_TARGET_DIR)/examples/%: examples/%.rs
	cargo build --target=$(STM32F4_TARGET) --release --example="$*"

$(STM32F4_DEBUG_TARGET_DIR)/$(BIN_NAME): src/main.rs
	cargo build --target=$(STM32F4_TARGET) --bin="$(BIN_NAME)"

$(STM32F4_DEBUG_TARGET_DIR)/%: stm32f4/src/bin/%.rs
	cargo build --target=$(STM32F4_TARGET) --bin="$*"

$(STM32F4_RELEASE_TARGET_DIR)/$(BIN_NAME): src/main.rs
	cargo build --target=$(STM32F4_TARGET) --release --bin="$(BIN_NAME)"

$(STM32F4_RELEASE_TARGET_DIR)/%: stm32f4/src/bin/%.rs
	cargo build --target=$(STM32F4_TARGET) --release --bin="$*"

# Objcopy to dest dir.
$(DEST_DIR)/example-%.debug.bin: $(STM32F4_DEBUG_TARGET_DIR)/examples/%
	rust-objcopy $(STM32F4_DEBUG_TARGET_DIR)/examples/$* --output-target "binary" $(DEST_DIR)/example-$*.debug.bin

$(DEST_DIR)/example-%.bin: $(STM32F4_RELEASE_TARGET_DIR)/examples/%
	rust-objcopy $(STM32F4_RELEASE_TARGET_DIR)/examples/$* --output-target "binary" $(DEST_DIR)/example-$*.bin

$(DEST_DIR)/%.debug.bin: $(STM32F4_DEBUG_TARGET_DIR)/%
	rust-objcopy $(STM32F4_DEBUG_TARGET_DIR)/$* --output-target "binary" $(DEST_DIR)/$*.debug.bin

$(DEST_DIR)/%.bin: $(STM32F4_RELEASE_TARGET_DIR)/%
	rust-objcopy $(STM32F4_RELEASE_TARGET_DIR)/$* --output-target "binary" $(DEST_DIR)/$*.bin

# uf2conv depending on whether for STM32F4
$(DEST_DIR)/example-%.debug.uf2: $(DEST_DIR)/example-%.debug.bin $(STM32F4_DEBUG_TARGET_DIR)/examples/%
	uf2conv --convert --family=STM32F4 --base 0x8010000 --output="$(DEST_DIR)/example-$*.debug.uf2" $(DEST_DIR)/example-$*.debug.bin

$(DEST_DIR)/example-%.uf2: $(DEST_DIR)/example-%.bin $(STM32F4_RELEASE_TARGET_DIR)/examples/%
	uf2conv --convert --family=STM32F4 --base 0x8010000 --output="$(DEST_DIR)/example-$*.uf2" $(DEST_DIR)/example-$*.bin

$(DEST_DIR)/%.debug.uf2: $(DEST_DIR)/%.debug.bin $(STM32F4_DEBUG_TARGET_DIR)/%
	uf2conv --convert --family=STM32F4 --base 0x8010000 --output="$(DEST_DIR)/$*.debug.uf2" $(DEST_DIR)/$*.debug.bin

$(DEST_DIR)/%.uf2: $(DEST_DIR)/%.bin $(STM32F4_RELEASE_TARGET_DIR)/%
	uf2conv --convert --family=STM32F4 --base 0x8010000 --output="$(DEST_DIR)/$*.uf2" $(DEST_DIR)/$*.bin
