interface axi_lite_if(input logic ACLK);

    // ---------------------------------------------------------
    // Reset
    // ---------------------------------------------------------
    logic ARESETn;


    // ---------------------------------------------------------
    // AXI-Lite Write Address Channel
    // ---------------------------------------------------------
    logic [31:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;


    // ---------------------------------------------------------
    // AXI-Lite Write Data Channel
    // ---------------------------------------------------------
    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WVALID;
    logic        WREADY;


    // ---------------------------------------------------------
    // AXI-Lite Write Response Channel
    // ---------------------------------------------------------
    logic [1:0] BRESP;
    logic       BVALID;
    logic       BREADY;


    // ---------------------------------------------------------
    // AXI-Lite Read Address Channel
    // ---------------------------------------------------------
    logic [31:0] ARADDR;
    logic        ARVALID;
    logic        ARREADY;


    // ---------------------------------------------------------
    // AXI-Lite Read Data Channel
    // ---------------------------------------------------------
    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RVALID;
    logic        RREADY;


    // =========================================================
    // DRIVER CLOCKING BLOCK
    // =========================================================
    //
    // The driver uses this clocking block to:
    //
    // 1. Drive AXI master signals into the DUT
    // 2. Sample AXI slave signals coming from the DUT
    //
    // input #1step:
    //     Sample DUT outputs just before the clock edge.
    //
    // output #0:
    //     Drive TB outputs at the clocking event.
    //
    // This helps avoid DUT/testbench race conditions.
    // =========================================================

    clocking driver_cb @(posedge ACLK);

        default input #1step output #0;


        // -----------------------------------------------------
        // Driver -> DUT
        // -----------------------------------------------------

        // Write address channel
        output AWADDR;
        output AWVALID;

        // Write data channel
        output WDATA;
        output WSTRB;
        output WVALID;

        // Write response channel
        output BREADY;

        // Read address channel
        output ARADDR;
        output ARVALID;

        // Read data channel
        output RREADY;


        // -----------------------------------------------------
        // DUT -> Driver
        // -----------------------------------------------------

        // Write address channel
        input AWREADY;

        // Write data channel
        input WREADY;

        // Write response channel
        input BRESP;
        input BVALID;

        // Read address channel
        input ARREADY;

        // Read data channel
        input RDATA;
        input RRESP;
        input RVALID;

    endclocking


    // =========================================================
    // MONITOR CLOCKING BLOCK
    // =========================================================
    //
    // The monitor is passive.
    //
    // It does NOT drive anything.
    // It only observes AXI signals and reconstructs transactions.
    // =========================================================

    clocking monitor_cb @(posedge ACLK);

        default input #1step output #0;


        // Write address channel
        input AWADDR;
        input AWVALID;
        input AWREADY;


        // Write data channel
        input WDATA;
        input WSTRB;
        input WVALID;
        input WREADY;


        // Write response channel
        input BRESP;
        input BVALID;
        input BREADY;


        // Read address channel
        input ARADDR;
        input ARVALID;
        input ARREADY;


        // Read data channel
        input RDATA;
        input RRESP;
        input RVALID;
        input RREADY;

    endclocking


endinterface
