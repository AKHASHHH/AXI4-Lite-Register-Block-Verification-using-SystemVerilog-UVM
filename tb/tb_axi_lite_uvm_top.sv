`timescale 1ns/1ps

module tb_axi_lite_uvm_top;

    import uvm_pkg::*;
    import axi_lite_pkg::*;

    // ---------------------------------------------------------
    // Clock
    // ---------------------------------------------------------

    logic ACLK;

    initial
        ACLK = 1'b0;

    always #5 ACLK = ~ACLK;


    // ---------------------------------------------------------
    // AXI-Lite Interface
    // ---------------------------------------------------------

    axi_lite_if axi_if(ACLK);


    // ---------------------------------------------------------
    // DUT
    // ---------------------------------------------------------

    axi_lite_regs dut (

        .ACLK    (ACLK),
        .ARESETn (axi_if.ARESETn),

        // Write address channel
        .AWADDR  (axi_if.AWADDR),
        .AWVALID (axi_if.AWVALID),
        .AWREADY (axi_if.AWREADY),

        // Write data channel
        .WDATA   (axi_if.WDATA),
        .WSTRB   (axi_if.WSTRB),
        .WVALID  (axi_if.WVALID),
        .WREADY  (axi_if.WREADY),

        // Write response channel
        .BRESP   (axi_if.BRESP),
        .BVALID  (axi_if.BVALID),
        .BREADY  (axi_if.BREADY),

        // Read address channel
        .ARADDR  (axi_if.ARADDR),
        .ARVALID (axi_if.ARVALID),
        .ARREADY (axi_if.ARREADY),

        // Read data channel
        .RDATA   (axi_if.RDATA),
        .RRESP   (axi_if.RRESP),
        .RVALID  (axi_if.RVALID),
        .RREADY  (axi_if.RREADY)

    );


    // ---------------------------------------------------------
    // Reset generation
    // ---------------------------------------------------------

    initial begin

        axi_if.ARESETn = 1'b0;

        repeat (5)
            @(posedge ACLK);

        axi_if.ARESETn = 1'b1;

    end


    // ---------------------------------------------------------
    // UVM Configuration + Start Test
    // ---------------------------------------------------------

    initial begin

        // Give the real interface instance to the
        // class-based UVM components.
        uvm_config_db#(virtual axi_lite_if)::set(
            null,
            "*",
            "vif",
            axi_if
        );

        run_test("axi_lite_test");

    end

endmodule
