class axi_lite_driver extends uvm_driver #(axi_lite_seq_item);

    `uvm_component_utils(axi_lite_driver)

    virtual axi_lite_if vif;


    // =========================================================
    // Constructor
    // =========================================================
    function new(string name = "axi_lite_driver",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction


    // =========================================================
    // Build Phase
    // =========================================================
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual axi_lite_if)::get(
                this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "Virtual interface not found")
        end

    endfunction


    // =========================================================
    // Main Driver
    // =========================================================
    task run_phase(uvm_phase phase);

        axi_lite_seq_item req;


        // Initialize AXI master outputs
        vif.AWADDR  <= '0;
        vif.AWVALID <= 0;

        vif.WDATA   <= '0;
        vif.WSTRB   <= '0;
        vif.WVALID  <= 0;

        vif.BREADY  <= 0;

        vif.ARADDR  <= '0;
        vif.ARVALID <= 0;

        vif.RREADY  <= 0;


        // Wait until reset is released
        wait (vif.ARESETn === 1'b1);

        // Move away from the reset-release edge
        @(negedge vif.ACLK);

        `uvm_info(
            "DRIVER",
            "Reset released - driver starting",
            UVM_LOW
        )


        forever begin

            seq_item_port.get_next_item(req);

            `uvm_info(
                "DRIVER",
                $sformatf(
                    "Received transaction: operation=%0d addr=0x%08h data=0x%08h strb=%04b",
                    req.operation,
                    req.addr,
                    req.data,
                    req.strb
                ),
                UVM_LOW
            )


            if (req.operation == AXI_WRITE) begin
                drive_write(req);
            end
            else begin
                drive_read(req);
            end


            seq_item_port.item_done();

        end

    endtask


    // =========================================================
    // AXI-Lite WRITE
    // =========================================================
    task drive_write(axi_lite_seq_item req);

        bit aw_done;
        bit w_done;


        `uvm_info(
            "DRIVER",
            "Starting AXI WRITE",
            UVM_LOW
        )


        aw_done = 0;
        w_done  = 0;


        // -----------------------------------------------------
        // Drive address and data on falling edge.
        //
        // They will therefore be stable before the next
        // rising edge, where the DUT samples them.
        // -----------------------------------------------------

        @(negedge vif.ACLK);

        vif.AWADDR  <= req.addr;
        vif.AWVALID <= 1;

        vif.WDATA   <= req.data;
        vif.WSTRB   <= req.strb;
        vif.WVALID  <= 1;


        // -----------------------------------------------------
        // Wait for AW and W handshakes independently.
        //
        // Handshake occurs on rising edge when:
        //
        // VALID == 1 && READY == 1
        // -----------------------------------------------------

        while (!(aw_done && w_done)) begin

            @(posedge vif.ACLK);

            if (!aw_done &&
                vif.AWVALID &&
                vif.AWREADY) begin

                aw_done = 1;

                `uvm_info(
                    "DRIVER",
                    "AW handshake completed",
                    UVM_LOW
                )

            end


            if (!w_done &&
                vif.WVALID &&
                vif.WREADY) begin

                w_done = 1;

                `uvm_info(
                    "DRIVER",
                    "W handshake completed",
                    UVM_LOW
                )

            end


            // Deassert VALID safely after the sampling edge
            @(negedge vif.ACLK);

            if (aw_done)
                vif.AWVALID <= 0;

            if (w_done)
                vif.WVALID <= 0;

        end


        // -----------------------------------------------------
        // WRITE RESPONSE
        // -----------------------------------------------------

        vif.BREADY <= 1;


        // Wait for BVALID && BREADY at rising edge
        do begin

            @(posedge vif.ACLK);

        end
        while (!(vif.BVALID && vif.BREADY));


        req.resp = vif.BRESP;


        `uvm_info(
            "DRIVER",
            $sformatf(
                "Write response received: BRESP=%02b",
                req.resp
            ),
            UVM_LOW
        )


        // Deassert BREADY after handshake
        @(negedge vif.ACLK);

        vif.BREADY <= 0;

    endtask


    // =========================================================
    // AXI-Lite READ
    // =========================================================
    task drive_read(axi_lite_seq_item req);

        `uvm_info(
            "DRIVER",
            "Starting AXI READ",
            UVM_LOW
        )


        // -----------------------------------------------------
        // Drive ARADDR and ARVALID on falling edge.
        //
        // This guarantees they are stable before the DUT's
        // next rising-edge sampling point.
        // -----------------------------------------------------

        @(negedge vif.ACLK);

        vif.ARADDR  <= req.addr;
        vif.ARVALID <= 1;


        // -----------------------------------------------------
        // Wait for a REAL AR handshake:
        //
        // ARVALID == 1
        // ARREADY == 1
        // at a rising edge
        // -----------------------------------------------------

        do begin

            @(posedge vif.ACLK);

        end
        while (!(vif.ARVALID && vif.ARREADY));


        `uvm_info(
            "DRIVER",
            "AR handshake completed",
            UVM_LOW
        )


        // -----------------------------------------------------
        // Move to falling edge before changing master outputs.
        // -----------------------------------------------------

        @(negedge vif.ACLK);

        vif.ARVALID <= 0;

        // Master is ready for read response
        vif.RREADY <= 1;


        // -----------------------------------------------------
        // Wait for a REAL R-channel handshake:
        //
        // RVALID == 1
        // RREADY == 1
        // at a rising edge
        // -----------------------------------------------------

        do begin

            @(posedge vif.ACLK);

        end
        while (!(vif.RVALID && vif.RREADY));


        // Capture response
        req.data = vif.RDATA;
        req.resp = vif.RRESP;


        `uvm_info(
            "DRIVER",
            $sformatf(
                "Read response received: RDATA=0x%08h RRESP=%02b",
                req.data,
                req.resp
            ),
            UVM_LOW
        )


        // Deassert RREADY after handshake
        @(negedge vif.ACLK);

        vif.RREADY <= 0;

    endtask


endclass
