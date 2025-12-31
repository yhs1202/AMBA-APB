VIVADO ?= vivado
PROJ := $(notdir $(CURDIR))
OUTDIR := out

SOURCES := $(shell find src -type f \( -name '*.v' -o -name '*.sv' \) 2>/dev/null)
XDC := $(wildcard constr/*.xdc)

.PHONY: all help check build sim bit clean veryclean

all: build

help:
	@echo "Targets:"
	@echo "  make build	  	  - run Vivado GUI build (uses build.tcl)"
	@echo "  make sim         - run Vivado Simulation (uses sim.tcl)"
	@echo "  make bit         - run Vivado Bitstream generation (uses bit.tcl)"
	@echo "  make clean       - remove out/ and Vivado work dirs"
	@echo "  make veryclean   - clean + IDE/OS leftovers"
	@echo ""
	@echo "Variables (override if needed):"
	@echo "  TOP=<top_module>    (default: $(TOP))"
	@echo ""
	@echo "Examples:"
	@echo "  make TOP=MyTopModule bit"
	@echo "  make bit"

check:
	@command -v $(VIVADO) >/dev/null 2>&1 || { \
	  echo "ERROR: '$(VIVADO)' not found in PATH"; exit 127; }

build: scripts/build.tcl
	@echo "Run Vivado build"
	$(VIVADO) -mode gui -source scripts/build.tcl &

sim: scripts/sim.tcl
	@echo "Run simulation" 
	$(VIVADO) -mode gui -source scripts/sim.tcl &

bit: scripts/bit.tcl
	@echo "Run Vivado bitstream generation"
	$(VIVADO) -mode gui -source scripts/bit.tcl &

clean:
	@rm -rf $(OUTDIR) .Xil .cache .runs .sim .gen *.log *.jou *.str

veryclean: clean
	@rm -rf .out .vscode .idea Thumbs.db .DS_Store .nvim
