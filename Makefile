# ==============================================================================
# Makefile para proyectos didácticos en NASM (x86 32 bits)
# ==============================================================================

NASM ?= nasm
NASMFLAGS ?= -f elf32 -g -F dwarf
LD ?= ld
LDFLAGS ?= -m elf_i386

SRC_DIR := src
BIN_DIR := bin

SOURCES := $(wildcard $(SRC_DIR)/*.asm)
OBJECTS := $(patsubst $(SRC_DIR)/%.asm, $(BIN_DIR)/%.o, $(SOURCES))
BINARIES := $(patsubst $(SRC_DIR)/%.asm, $(BIN_DIR)/%, $(SOURCES))

.PHONY: all clean run-hello run-pointers run-control-flow run-subroutines

all: $(BINARIES)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(BIN_DIR)/%.o: $(SRC_DIR)/%.asm | $(BIN_DIR)
	$(NASM) $(NASMFLAGS) $< -o $@

$(BIN_DIR)/%: $(BIN_DIR)/%.o
	$(LD) $(LDFLAGS) $< -o $@

run-hello: $(BIN_DIR)/HelloW
	@./$(BIN_DIR)/HelloW

run-pointers: $(BIN_DIR)/pointers
	@./$(BIN_DIR)/pointers

run-control-flow: $(BIN_DIR)/control_flow
	@./$(BIN_DIR)/control_flow

run-subroutines: $(BIN_DIR)/subroutines
	@./$(BIN_DIR)/subroutines

clean:
	rm -rf $(BIN_DIR)
