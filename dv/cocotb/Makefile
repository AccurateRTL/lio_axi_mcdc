# Copyright AccurateRTL contributors.
# Licensed under the MIT License, see LICENSE for details.
# SPDX-License-Identifier: MIT

# defaults
#SIM ?= verilator
SIM ?= icarus


#EXTRA_ARGS += -Wno-fatal -Irtl
#SIM ?= vcs
#EXTRA_ARGS += --trace-fst --trace-structs
#EXTRA_ARGS += --trace --trace-fst --trace-structs

TOPLEVEL_LANG ?= verilog


VERILOG_SOURCES += ../../hw/rtl/lio_mb_mcdc.sv ../../hw/rtl/lio_axi_mcdc.sv

TOPLEVEL = lio_axi_mcdc

# MODULE is the basename of the Python test file
MODULE = test_axi_mcdc

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
