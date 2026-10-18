# Makefile for PCIe Data Link Layer UVM Verification Suite

RTL_SRC = ../rtl/pcie_crc32.sv \
          ../rtl/pcie_tx_engine.sv \
          ../rtl/pcie_rx_engine.sv \
          ../rtl/pcie_dll_top.sv

TB_SRC  = ../tb/pcie_if.sv \
          ../tb/tb_top.sv

INCDIR  = +incdir+../tb +incdir+../rtl

TESTNAME ?= pcie_test
SEED     ?= 1

all: compile run

compile:
	vlib work
	vlog -sv $(INCDIR) $(RTL_SRC) $(TB_SRC)

run:
	vsim -c -do "run -all; quit" +UVM_TESTNAME=$(TESTNAME) +ntb_random_seed=$(SEED) -l sim.log tb_top

wave:
	gtkwave dump.vcd &

clean:
	rm -rf work run_logs transcript *.log *.vcd *.wlf