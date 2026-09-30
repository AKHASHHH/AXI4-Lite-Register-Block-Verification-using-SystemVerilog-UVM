#!/bin/tcsh -f

echo "========================================"
echo "AXI-LITE VERIFICATION REGRESSION"
echo "========================================"

set PROJECT_ROOT = `pwd`
set SIM_DIR      = "$PROJECT_ROOT/sim"
set LOG_DIR      = "$PROJECT_ROOT/logs"
set URG = "/eda/synopsys/vcs/Y-2026.03/bin/urg"

echo ""
echo "Project root: $PROJECT_ROOT"
echo "Simulation directory: $SIM_DIR"
echo "Log directory: $LOG_DIR"
echo "========================================"
echo "STAGE 1: DIRECTED TESTS + SVA"
echo "========================================"

cd "$SIM_DIR"
rm -rf simv_directed simv_directed.daidir simv_directed.vdb directed.vdb simv simv.daidir simv.vdb coverage_report
echo "Compiling directed testbench..."

vcs -full64 -sverilog -timescale=1ns/1ps \
    -cm line+cond+fsm+tgl+branch \
    ../rtl/axi_lite_regs.sv \
    ../assertions/axi_lite_assertions.sv \
    ../tb/tb_axi_lite_regs.sv \
    -top tb_axi_lite_regs \
    -o simv_directed \
    >& "$LOG_DIR/directed_compile.log"

if ($status != 0) then
    echo "DIRECTED COMPILE: FAIL"
    echo "See: $LOG_DIR/directed_compile.log"
    exit 1
endif

echo "DIRECTED COMPILE: PASS"
echo "Running directed regression..."

./simv_directed -cm line+cond+fsm+tgl+branch >& "$LOG_DIR/directed_run.log"

if ($status != 0) then
    echo "DIRECTED RUN: FAIL"
    echo "See: $LOG_DIR/directed_run.log"
    exit 1
endif

grep -q "ALL 12 DIRECTED TESTS PASSED" "$LOG_DIR/directed_run.log"

if ($status == 0) then
    echo "DIRECTED + SVA: PASS"
    cp -r simv_directed.vdb directed.vdb
else
    echo "DIRECTED + SVA: FAIL"
    echo "See: $LOG_DIR/directed_run.log"
    exit 1
endif

echo "========================================"
echo "STAGE 2: UVM + COVERAGE"
echo "========================================"

cd "$SIM_DIR"

echo "Compiling UVM environment with coverage..."

vcs -full64 -sverilog -ntb_opts uvm -timescale=1ns/1ps \
    -cm line+cond+fsm+tgl+branch \
    +incdir+../tb \
    ../rtl/axi_lite_regs.sv \
    ../tb/axi_lite_if.sv \
    ../tb/axi_lite_pkg.sv \
    ../tb/tb_axi_lite_uvm_top.sv \
    -top tb_axi_lite_uvm_top \
    -o simv \
    >& "$LOG_DIR/uvm_compile.log"

if ($status != 0) then
    echo "UVM COMPILE: FAIL"
    echo "See: $LOG_DIR/uvm_compile.log"
    exit 1
endif

echo "UVM COMPILE: PASS"
echo "Running UVM constrained-random/negative/WSTRB regression..."

./simv +UVM_TESTNAME=axi_lite_test \
    -cm line+cond+fsm+tgl+branch \
    >& "$LOG_DIR/uvm_run.log"

if ($status != 0) then
    echo "UVM RUN: FAIL"
    echo "See: $LOG_DIR/uvm_run.log"
    exit 1
endif

grep -q "UVM_ERROR :    0" "$LOG_DIR/uvm_run.log"

if ($status != 0) then
    echo "UVM REGRESSION: FAIL - UVM errors detected"
    echo "See: $LOG_DIR/uvm_run.log"
    exit 1
endif

grep -q "UVM_FATAL :    0" "$LOG_DIR/uvm_run.log"

if ($status != 0) then
    echo "UVM REGRESSION: FAIL - UVM fatal detected"
    echo "See: $LOG_DIR/uvm_run.log"
    exit 1
endif

echo "UVM REGRESSION: PASS"

echo "Generating coverage report..."

rm -rf coverage_report
$URG -dir directed.vdb -dir simv.vdb -report coverage_report \
    >& "$LOG_DIR/coverage_report.log"

if ($status != 0) then
    echo "COVERAGE REPORT: FAIL"
    echo "See: $LOG_DIR/coverage_report.log"
    exit 1
endif

echo "COVERAGE REPORT: PASS"
echo "========================================"
echo "STAGE 3: UVM RAL"
echo "========================================"

cd "$SIM_DIR"

echo "Running RAL regression..."

./simv +UVM_TESTNAME=axi_lite_ral_test \
    >& "$LOG_DIR/ral_run.log"

if ($status != 0) then
    echo "RAL RUN: FAIL"
    echo "See: $LOG_DIR/ral_run.log"
    exit 1
endif

grep -q "UVM_ERROR :    0" "$LOG_DIR/ral_run.log"

if ($status != 0) then
    echo "RAL REGRESSION: FAIL - UVM errors detected"
    echo "See: $LOG_DIR/ral_run.log"
    exit 1
endif

grep -q "UVM_FATAL :    0" "$LOG_DIR/ral_run.log"

if ($status != 0) then
    echo "RAL REGRESSION: FAIL - UVM fatal detected"
    echo "See: $LOG_DIR/ral_run.log"
    exit 1
endif

grep -q "AXI-Lite RAL sequence completed" "$LOG_DIR/ral_run.log"

if ($status != 0) then
    echo "RAL REGRESSION: FAIL - RAL sequence did not complete"
    echo "See: $LOG_DIR/ral_run.log"
    exit 1
endif

echo "RAL REGRESSION: PASS"
echo "========================================"
echo "REGRESSION SUMMARY"
echo "========================================"
echo "DIRECTED + SVA     : PASS"
echo "UVM + COVERAGE     : PASS"
echo "UVM RAL            : PASS"
echo "----------------------------------------"
echo "OVERALL REGRESSION : PASS"
echo "========================================"
exit 0
