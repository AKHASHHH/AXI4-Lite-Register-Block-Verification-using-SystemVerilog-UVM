class axi_lite_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi_lite_scoreboard)

    // Receives transactions from the monitor
    uvm_analysis_imp #(axi_lite_seq_item,
                       axi_lite_scoreboard) analysis_imp;

    // Reference model of writable registers
    logic [31:0] expected_control;
    logic [31:0] expected_config;
    logic [31:0] expected_irq_enable;


    // ---------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------
    function new(string name = "axi_lite_scoreboard",
                 uvm_component parent = null);

        super.new(name, parent);

        analysis_imp = new("analysis_imp", this);

        // DUT reset values
        expected_control    = 32'h00000000;
        expected_config     = 32'h00000000;
        expected_irq_enable = 32'h00000000;

    endfunction


    // ---------------------------------------------------------
    // Apply AXI-Lite write strobes
    // ---------------------------------------------------------
    function automatic logic [31:0] apply_wstrb(
        input logic [31:0] old_value,
        input logic [31:0] new_value,
        input logic [3:0]  strb
    );

        logic [31:0] result;

        result = old_value;

        if (strb[0])
            result[7:0] = new_value[7:0];

        if (strb[1])
            result[15:8] = new_value[15:8];

        if (strb[2])
            result[23:16] = new_value[23:16];

        if (strb[3])
            result[31:24] = new_value[31:24];

        return result;

    endfunction


    // ---------------------------------------------------------
    // Receive transactions from monitor
    // ---------------------------------------------------------
    function void write(axi_lite_seq_item tr);

        logic [31:0] expected_data;
        logic [1:0]  expected_resp;


        // =====================================================
        // WRITE TRANSACTION
        // =====================================================
        if (tr.operation == AXI_WRITE) begin

            // Determine expected write response
            case (tr.addr)

                32'h00000000,
                32'h00000008,
                32'h0000000C:
                    expected_resp = 2'b00;   // OKAY

                default:
                    expected_resp = 2'b10;   // SLVERR

            endcase


            // Check BRESP
            if (tr.resp !== expected_resp) begin

                `uvm_error("SCOREBOARD",
                    $sformatf(
                        "Write response mismatch: addr=0x%08h expected_resp=%02b actual_resp=%02b",
                        tr.addr,
                        expected_resp,
                        tr.resp
                    )
                )

            end


            // Update reference model only if write succeeded
            if (tr.resp == 2'b00) begin

                case (tr.addr)

                    // CONTROL register
                    32'h00000000: begin

                        expected_control =
                            apply_wstrb(
                                expected_control,
                                tr.data,
                                tr.strb
                            );

                        // START bit [0] is self-clearing
                        expected_control[0] = 1'b0;

                    end


                    // CONFIG register
                    32'h00000008: begin

                        expected_config =
                            apply_wstrb(
                                expected_config,
                                tr.data,
                                tr.strb
                            );

                    end


                    // IRQ_ENABLE register
                    32'h0000000C: begin

                        expected_irq_enable =
                            apply_wstrb(
                                expected_irq_enable,
                                tr.data,
                                tr.strb
                            );

                    end

                endcase

            end

        end


        // =====================================================
        // READ TRANSACTION
        // =====================================================
        else begin

            // Determine expected read response
            case (tr.addr)

                32'h00000000,
                32'h00000004,
                32'h00000008,
                32'h0000000C:
                    expected_resp = 2'b00;   // OKAY

                default:
                    expected_resp = 2'b10;   // SLVERR

            endcase


            // Check RRESP
            if (tr.resp !== expected_resp) begin

                `uvm_error("SCOREBOARD",
                    $sformatf(
                        "Read response mismatch: addr=0x%08h expected_resp=%02b actual_resp=%02b",
                        tr.addr,
                        expected_resp,
                        tr.resp
                    )
                )

            end


            // -------------------------------------------------
            // Invalid read
            // Expected:
            // RRESP = SLVERR
            // RDATA = 0
            // -------------------------------------------------
            if (expected_resp == 2'b10) begin

                if (tr.data !== 32'h00000000) begin

                    `uvm_error("SCOREBOARD",
                        $sformatf(
                            "Invalid read returned non-zero data: addr=0x%08h data=0x%08h",
                            tr.addr,
                            tr.data
                        )
                    )

                end

            end


            // -------------------------------------------------
            // STATUS register
            // Dynamic register:
            // [2] error
            // [1] done
            // [0] busy
            // [31:3] must always be zero
            // -------------------------------------------------
            else if (tr.addr == 32'h00000004) begin

                if (tr.data[31:3] !== 29'b0) begin

                    `uvm_error("SCOREBOARD",
                        $sformatf(
                            "STATUS reserved bits are non-zero: data=0x%08h",
                            tr.data
                        )
                    )

                end

            end


            // -------------------------------------------------
            // Normal register read
            // -------------------------------------------------
            else begin

                case (tr.addr)

                    32'h00000000:
                        expected_data = expected_control;

                    32'h00000008:
                        expected_data = expected_config;

                    32'h0000000C:
                        expected_data = expected_irq_enable;

                    default:
                        expected_data = 32'h00000000;

                endcase


                // Compare expected data with actual DUT data
                if (tr.data !== expected_data) begin

                    `uvm_error("SCOREBOARD",
                        $sformatf(
                            "Read mismatch: addr=0x%08h expected=0x%08h actual=0x%08h",
                            tr.addr,
                            expected_data,
                            tr.data
                        )
                    )

                end
                else begin

                    `uvm_info("SCOREBOARD",
                        $sformatf(
                            "Read match: addr=0x%08h data=0x%08h",
                            tr.addr,
                            tr.data
                        ),
                        UVM_LOW
                    )

                end

            end

        end

    endfunction

endclass
