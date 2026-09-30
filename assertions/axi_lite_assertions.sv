`timescale 1ns/1ps

module axi_lite_assertions (

    input logic        ACLK,
    input logic        ARESETn,

    // Write address channel
    input logic [31:0] AWADDR,
    input logic        AWVALID,
    input logic        AWREADY,

    // Write data channel
    input logic [31:0] WDATA,
    input logic [3:0]  WSTRB,
    input logic        WVALID,
    input logic        WREADY,

    // Write response channel
    input logic [1:0]  BRESP,
    input logic        BVALID,
    input logic        BREADY,

    // Read address channel
    input logic [31:0] ARADDR,
    input logic        ARVALID,
    input logic        ARREADY,

    // Read response channel
    input logic [31:0] RDATA,
    input logic [1:0]  RRESP,
    input logic        RVALID,
    input logic        RREADY,

    // Internal DUT state
    input logic        aw_pending,
    input logic        w_pending,

    input logic [31:0] control_reg,
    input logic [31:0] config_reg,
    input logic [31:0] irq_enable_reg,

    input logic        busy,
    input logic        done,
    input logic        error
);


// ============================================================
// ASSERTION 1:
// B-channel response must remain stable during backpressure
// ============================================================

property p_bvalid_stable;
    @(posedge ACLK)
    disable iff (!ARESETn)

    BVALID && !BREADY
    |=>
    BVALID && $stable(BRESP);
endproperty

a_bvalid_stable:
    assert property (p_bvalid_stable)
    else $error(
        "ASSERTION 1 FAILED: BVALID/BRESP changed during backpressure"
    );


// ============================================================
// ASSERTION 2:
// R-channel response must remain stable during backpressure
// ============================================================

property p_rvalid_stable;
    @(posedge ACLK)
    disable iff (!ARESETn)

    RVALID && !RREADY
    |=>
    RVALID && $stable(RDATA) && $stable(RRESP);
endproperty

a_rvalid_stable:
    assert property (p_rvalid_stable)
    else $error(
        "ASSERTION 2 FAILED: RVALID/RDATA/RRESP changed during backpressure"
    );


// ============================================================
// ASSERTION 3:
// AW payload must remain stable while stalled
// ============================================================

property p_aw_stable;
    @(posedge ACLK)
    disable iff (!ARESETn)

    AWVALID && !AWREADY
    |=>
    AWVALID && $stable(AWADDR);
endproperty

a_aw_stable:
    assert property (p_aw_stable)
    else $error(
        "ASSERTION 3 FAILED: AWVALID/AWADDR changed during backpressure"
    );


// ============================================================
// ASSERTION 4:
// W payload must remain stable while stalled
// ============================================================

property p_w_stable;
    @(posedge ACLK)
    disable iff (!ARESETn)

    WVALID && !WREADY
    |=>
    WVALID && $stable(WDATA) && $stable(WSTRB);
endproperty

a_w_stable:
    assert property (p_w_stable)
    else $error(
        "ASSERTION 4 FAILED: WVALID/WDATA/WSTRB changed during backpressure"
    );


// ============================================================
// ASSERTION 5:
// AR payload must remain stable while stalled
// ============================================================

property p_ar_stable;
    @(posedge ACLK)
    disable iff (!ARESETn)

    ARVALID && !ARREADY
    |=>
    ARVALID && $stable(ARADDR);
endproperty

a_ar_stable:
    assert property (p_ar_stable)
    else $error(
        "ASSERTION 5 FAILED: ARVALID/ARADDR changed during backpressure"
    );


// ============================================================
// ASSERTION 6:
// A new B response requires a complete pending write
// ============================================================

property p_b_valid;
    @(posedge ACLK)
    disable iff (!ARESETn)

    $rose(BVALID)
    |->
    $past(aw_pending && w_pending);
endproperty

a_b_valid:
    assert property (p_b_valid)
    else $error(
        "ASSERTION 6 FAILED: BVALID rose without a complete pending write"
    );


// ============================================================
// ASSERTION 7:
// A new R response requires a previous AR handshake
// ============================================================

property p_r_valid;
    @(posedge ACLK)
    disable iff (!ARESETn)

    $rose(RVALID)
    |->
    $past(ARVALID && ARREADY);
endproperty

a_r_valid:
    assert property (p_r_valid)
    else $error(
        "ASSERTION 7 FAILED: RVALID rose without a previous read-address handshake"
    );


// ============================================================
// ASSERTION 8:
// Reset must clear important DUT state
// ============================================================

property p_reset_check;
    @(posedge ACLK)

    !ARESETn
    |=>
    !BVALID &&
    !RVALID &&
    (control_reg == 32'h00000000) &&
    (config_reg == 32'h00000000) &&
    (irq_enable_reg == 32'h00000000) &&
    !busy &&
    !done &&
    !error;
endproperty

a_reset_check:
    assert property (p_reset_check)
    else $error(
        "ASSERTION 8 FAILED: DUT state was not cleared by reset"
    );


// ============================================================
// ASSERTION 9:
// START while idle must cause BUSY to assert
// ============================================================

property p_start_busy;
    @(posedge ACLK)
    disable iff (!ARESETn)

    control_reg[0] && !busy
    |=>
    busy;
endproperty

a_start_busy:
    assert property (p_start_busy)
    else $error(
        "ASSERTION 9 FAILED: START did not cause BUSY to assert"
    );


// ============================================================
// ASSERTION 10:
// START must self-clear
// ============================================================

property p_start_self_clear;
    @(posedge ACLK)
    disable iff (!ARESETn)

    control_reg[0] && !busy
    |=>
    !control_reg[0];
endproperty

a_start_self_clear:
    assert property (p_start_self_clear)
    else $error(
        "ASSERTION 10 FAILED: START did not self-clear"
    );


// ============================================================
// ASSERTION 11:
// Once BUSY rises, operation must complete within 5 cycles
// ============================================================

property p_busy_done;
    @(posedge ACLK)
    disable iff (!ARESETn)

    $rose(busy)
    |->
    ##[1:5] done;
endproperty

a_busy_done:
    assert property (p_busy_done)
    else $error(
        "ASSERTION 11 FAILED: Operation did not complete within 5 cycles"
    );


// ============================================================
// ASSERTION 12:
// DONE and BUSY must not be asserted simultaneously
// ============================================================

property p_done_not_busy;
    @(posedge ACLK)
    disable iff (!ARESETn)

    done
    |->
    !busy;
endproperty

a_done_not_busy:
    assert property (p_done_not_busy)
    else $error(
        "ASSERTION 12 FAILED: DONE and BUSY are asserted simultaneously"
    );

endmodule


// ============================================================
// Bind assertion module to AXI-Lite DUT
// ============================================================

bind axi_lite_regs axi_lite_assertions axi_assertions (

    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .AWADDR         (AWADDR),
    .AWVALID        (AWVALID),
    .AWREADY        (AWREADY),

    .WDATA          (WDATA),
    .WSTRB          (WSTRB),
    .WVALID         (WVALID),
    .WREADY         (WREADY),

    .BRESP          (BRESP),
    .BVALID         (BVALID),
    .BREADY         (BREADY),

    .ARADDR         (ARADDR),
    .ARVALID        (ARVALID),
    .ARREADY        (ARREADY),

    .RDATA          (RDATA),
    .RRESP          (RRESP),
    .RVALID         (RVALID),
    .RREADY         (RREADY),

    .aw_pending     (aw_pending),
    .w_pending      (w_pending),

    .control_reg    (control_reg),
    .config_reg     (config_reg),
    .irq_enable_reg (irq_enable_reg),

    .busy           (busy),
    .done           (done),
    .error          (error)
);
