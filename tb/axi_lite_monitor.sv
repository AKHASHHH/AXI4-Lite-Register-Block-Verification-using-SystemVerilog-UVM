class axi_lite_monitor extends uvm_monitor;

    `uvm_component_utils(axi_lite_monitor)

    virtual axi_lite_if vif;

    uvm_analysis_port #(axi_lite_seq_item) ap;

    // Temporary storage for write transaction
    logic [31:0] captured_awaddr;
    logic [31:0] captured_wdata;
    logic [3:0]  captured_wstrb;

    bit aw_seen;
    bit w_seen;

    // Temporary storage for read transaction
    logic [31:0] captured_araddr;
    bit ar_seen;


    // ---------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------
    function new(string name = "axi_lite_monitor",
                 uvm_component parent = null);

        super.new(name, parent);

        ap = new("ap", this);

    endfunction


    // ---------------------------------------------------------
    // Build phase
    // Get virtual interface from config_db
    // ---------------------------------------------------------
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual axi_lite_if)::get(
                this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")

    endfunction


    // ---------------------------------------------------------
    // Monitor AXI-Lite transactions
    // ---------------------------------------------------------
    task run_phase(uvm_phase phase);

        axi_lite_seq_item tr;

        aw_seen = 0;
        w_seen  = 0;
        ar_seen = 0;

        forever begin

            @(vif.monitor_cb);


            // -------------------------------------------------
            // Capture write address handshake
            // -------------------------------------------------
            if (vif.monitor_cb.AWVALID &&
                vif.monitor_cb.AWREADY) begin

                captured_awaddr = vif.monitor_cb.AWADDR;
                aw_seen = 1;

            end


            // -------------------------------------------------
            // Capture write data handshake
            // -------------------------------------------------
            if (vif.monitor_cb.WVALID &&
                vif.monitor_cb.WREADY) begin

                captured_wdata = vif.monitor_cb.WDATA;
                captured_wstrb = vif.monitor_cb.WSTRB;
                w_seen = 1;

            end


            // -------------------------------------------------
            // Complete write transaction after B handshake
            // -------------------------------------------------
            if (aw_seen &&
                w_seen &&
                vif.monitor_cb.BVALID &&
                vif.monitor_cb.BREADY) begin

                tr = axi_lite_seq_item::type_id::create("tr");

                tr.operation = AXI_WRITE;
                tr.addr      = captured_awaddr;
                tr.data      = captured_wdata;
                tr.strb      = captured_wstrb;
                tr.resp      = vif.monitor_cb.BRESP;

                ap.write(tr);

                aw_seen = 0;
                w_seen  = 0;

            end


            // -------------------------------------------------
            // Capture read address handshake
            // -------------------------------------------------
            if (vif.monitor_cb.ARVALID &&
                vif.monitor_cb.ARREADY) begin

                captured_araddr = vif.monitor_cb.ARADDR;
                ar_seen = 1;

            end


            // -------------------------------------------------
            // Complete read transaction after R handshake
            // -------------------------------------------------
            if (ar_seen &&
                vif.monitor_cb.RVALID &&
                vif.monitor_cb.RREADY) begin

                tr = axi_lite_seq_item::type_id::create("tr");

                tr.operation = AXI_READ;
                tr.addr      = captured_araddr;
                tr.data      = vif.monitor_cb.RDATA;
                tr.strb      = 4'b0000;
                tr.resp      = vif.monitor_cb.RRESP;

                ap.write(tr);

                ar_seen = 0;

            end

        end

    endtask

endclass
