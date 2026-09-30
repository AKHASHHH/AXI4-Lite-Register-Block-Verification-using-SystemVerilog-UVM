`timescale 1ns/1ps

module tb_axi_lite_regs;

    // ============================================================
    // AXI-Lite signals
    // ============================================================

    logic        ACLK;
    logic        ARESETn;

    logic [31:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;

    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WVALID;
    logic        WREADY;

    logic [1:0]  BRESP;
    logic        BVALID;
    logic        BREADY;

    logic [31:0] ARADDR;
    logic        ARVALID;
    logic        ARREADY;

    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RVALID;
    logic        RREADY;


    // ============================================================
    // Testbench variables
    // ============================================================

    logic [31:0] read_data;
    logic [1:0]  read_resp;
    logic [1:0]  write_resp;

    logic [31:0] status_before_write;

    integer pass_count;
    integer fail_count;


    // ============================================================
    // DUT
    // ============================================================

    axi_lite_regs dut (
        .ACLK     (ACLK),
        .ARESETn  (ARESETn),

        .AWADDR   (AWADDR),
        .AWVALID  (AWVALID),
        .AWREADY  (AWREADY),

        .WDATA    (WDATA),
        .WSTRB    (WSTRB),
        .WVALID   (WVALID),
        .WREADY   (WREADY),

        .BRESP    (BRESP),
        .BVALID   (BVALID),
        .BREADY   (BREADY),

        .ARADDR   (ARADDR),
        .ARVALID  (ARVALID),
        .ARREADY  (ARREADY),

        .RDATA    (RDATA),
        .RRESP    (RRESP),
        .RVALID   (RVALID),
        .RREADY   (RREADY)
    );


    // ============================================================
    // Clock
    //
    // Period = 10 ns
    // Frequency = 100 MHz
    // ============================================================

    initial begin
        ACLK = 1'b0;
    end

    always #5 ACLK = ~ACLK;


    // ============================================================
    // Standard AXI-Lite write task
    // ============================================================

    task automatic axi_write (
        input  logic [31:0] addr,
        input  logic [31:0] data,
        input  logic [3:0]  strb,
        output logic [1:0]  resp
    );

        begin

            // -----------------------------
            // Send write address
            // -----------------------------
            @(negedge ACLK);

            AWADDR  = addr;
            AWVALID = 1'b1;

            do begin
                @(posedge ACLK);
            end while (!AWREADY);

            @(negedge ACLK);
            AWVALID = 1'b0;


            // -----------------------------
            // Send write data
            // -----------------------------
            WDATA  = data;
            WSTRB  = strb;
            WVALID = 1'b1;

            do begin
                @(posedge ACLK);
            end while (!WREADY);

            @(negedge ACLK);
            WVALID = 1'b0;


            // -----------------------------
            // Wait for write response
            // -----------------------------
            BREADY = 1'b1;

            do begin
                @(posedge ACLK);
            end while (!BVALID);

            resp = BRESP;

            $display(
                "WRITE RESPONSE: addr=%h data=%h strb=%b BRESP=%b",
                addr, data, strb, resp
            );

            @(negedge ACLK);
            BREADY = 1'b0;

        end

    endtask


    // ============================================================
    // Standard AXI-Lite read task
    // ============================================================

    task automatic axi_read (
        input  logic [31:0] addr,
        output logic [31:0] data,
        output logic [1:0]  resp
    );

        begin

            // -----------------------------
            // Send read address
            // -----------------------------
            @(negedge ACLK);

            ARADDR  = addr;
            ARVALID = 1'b1;

            do begin
                @(posedge ACLK);
            end while (!ARREADY);

            @(negedge ACLK);
            ARVALID = 1'b0;


            // -----------------------------
            // Accept read response
            // -----------------------------
            RREADY = 1'b1;

            do begin
                @(posedge ACLK);
            end while (!RVALID);

            data = RDATA;
            resp = RRESP;

            @(negedge ACLK);
            RREADY = 1'b0;

        end

    endtask


    // ============================================================
    // MAIN TEST SEQUENCE
    // ============================================================

    initial begin

        pass_count = 0;
        fail_count = 0;

        // --------------------------------------------------------
        // Initialize master-driven signals
        // --------------------------------------------------------

        ARESETn = 1'b0;

        AWADDR  = 32'b0;
        AWVALID = 1'b0;

        WDATA   = 32'b0;
        WSTRB   = 4'b0;
        WVALID  = 1'b0;

        BREADY  = 1'b0;

        ARADDR  = 32'b0;
        ARVALID = 1'b0;

        RREADY  = 1'b0;


        // ========================================================
        // INITIAL RESET
        // ========================================================

        $display("");
        $display("========================================");
        $display("INITIAL RESET");
        $display("========================================");

        repeat (2) @(posedge ACLK);

        @(negedge ACLK);
        ARESETn = 1'b1;

        repeat (2) @(posedge ACLK);


        // ========================================================
        // TEST 1
        // CONFIG full write/read
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 1: CONFIG WRITE / READ");
        $display("========================================");

        axi_write(
            32'h00000008,
            32'hDEADBEEF,
            4'b1111,
            write_resp
        );

        axi_read(
            32'h00000008,
            read_data,
            read_resp
        );

        if ((write_resp == 2'b00) &&
            (read_resp  == 2'b00) &&
            (read_data  == 32'hDEADBEEF)) begin

            $display("TEST 1 PASS: CONFIG = %h", read_data);
            pass_count = pass_count + 1;

        end
        else begin

            $display(
                "TEST 1 FAIL: data=%h WRESP=%b RRESP=%b",
                read_data,
                write_resp,
                read_resp
            );

            fail_count = fail_count + 1;

        end


        // ========================================================
        // TEST 2
        // IRQ_ENABLE write/read
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 2: IRQ_ENABLE WRITE / READ");
        $display("========================================");

        axi_write(
            32'h0000000C,
            32'h00000001,
            4'b1111,
            write_resp
        );

        axi_read(
            32'h0000000C,
            read_data,
            read_resp
        );

        if ((write_resp == 2'b00) &&
            (read_resp  == 2'b00) &&
            (read_data  == 32'h00000001)) begin

            $display("TEST 2 PASS: IRQ_ENABLE = %h", read_data);
            pass_count = pass_count + 1;

        end
        else begin

            $display("TEST 2 FAIL");
            fail_count = fail_count + 1;

        end


        // ========================================================
        // TEST 3
        // Partial WSTRB write
        //
        // old = 11223344
        // new = AABBCCDD
        // strb = 0101
        //
        // expected = 11BB33DD
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 3: PARTIAL WSTRB WRITE");
        $display("========================================");

        axi_write(
            32'h00000008,
            32'h11223344,
            4'b1111,
            write_resp
        );

        axi_write(
            32'h00000008,
            32'hAABBCCDD,
            4'b0101,
            write_resp
        );

        axi_read(
            32'h00000008,
            read_data,
            read_resp
        );

        if ((read_resp == 2'b00) &&
            (read_data == 32'h11BB33DD)) begin

            $display(
                "TEST 3 PASS: expected=11BB33DD actual=%h",
                read_data
            );

            pass_count = pass_count + 1;

        end
        else begin

            $display(
                "TEST 3 FAIL: expected=11BB33DD actual=%h",
                read_data
            );

            fail_count = fail_count + 1;

        end


        // ========================================================
        // TEST 4
        // Invalid write address
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 4: INVALID WRITE");
        $display("========================================");

        axi_write(
            32'h00000010,
            32'h12345678,
            4'b1111,
            write_resp
        );

        if (write_resp == 2'b10) begin

            $display("TEST 4 PASS: SLVERR received");
            pass_count = pass_count + 1;

        end
        else begin

            $display(
                "TEST 4 FAIL: expected BRESP=10 actual=%b",
                write_resp
            );

            fail_count = fail_count + 1;

        end


        // ========================================================
        // TEST 5
        // Invalid read address
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 5: INVALID READ");
        $display("========================================");

        axi_read(
            32'h00000010,
            read_data,
            read_resp
        );

        if ((read_resp == 2'b10) &&
            (read_data == 32'h00000000)) begin

            $display(
                "TEST 5 PASS: RRESP=SLVERR RDATA=%h",
                read_data
            );

            pass_count = pass_count + 1;

        end
        else begin

            $display(
                "TEST 5 FAIL: RRESP=%b RDATA=%h",
                read_resp,
                read_data
            );

            fail_count = fail_count + 1;

        end


        // ========================================================
        // TEST 6
        // CONTROL START -> BUSY -> DONE
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 6: START -> BUSY -> DONE");
        $display("========================================");

        // Read STATUS before START
        axi_read(
            32'h00000004,
            read_data,
            read_resp
        );

        $display("STATUS before START = %h", read_data);


        // Start operation
        axi_write(
            32'h00000000,
            32'h00000001,
            4'b1111,
            write_resp
        );


        // Read STATUS during operation
        axi_read(
            32'h00000004,
            read_data,
            read_resp
        );

        $display("STATUS during operation = %h", read_data);
        $display(
            "busy=%b done=%b error=%b",
            read_data[0],
            read_data[1],
            read_data[2]
        );

        if ((read_resp == 2'b00) &&
            (read_data[0] == 1'b1) &&
            (read_data[1] == 1'b0) &&
            (read_data[2] == 1'b0)) begin

            $display("BUSY CHECK PASS");

        end
        else begin

            $display("BUSY CHECK FAIL");
            fail_count++;
        end
        
        // --------------------------------------------------------
        // Attempt START again while DUT is already busy.
        // This exercises control_reg[0]=1 while busy=1.
        // --------------------------------------------------------

        axi_write(
            32'h00000000,
            32'h00000001,
            4'b1111,
            write_resp
        );

        if (write_resp == 2'b00) begin
            $display("START-WHILE-BUSY WRITE ACCEPTED");
        end
        else begin
            $display("START-WHILE-BUSY WRITE FAILED: BRESP=%b", write_resp);
            fail_count = fail_count + 1;
        end


        // Wait long enough for operation to finish
        repeat (12) @(posedge ACLK);


        // Read STATUS after operation
        axi_read(
            32'h00000004,
            read_data,
            read_resp
        );

        $display("STATUS after operation = %h", read_data);
        $display(
            "busy=%b done=%b error=%b",
            read_data[0],
            read_data[1],
            read_data[2]
        );


        // Read CONTROL to verify START self-cleared
        axi_read(
            32'h00000000,
            read_data,
            read_resp
        );

        if ((read_resp == 2'b00) &&
            (read_data[0] == 1'b0)) begin

            $display("START SELF-CLEAR CHECK PASS");
            pass_count = pass_count + 1;

        end
        else begin

            $display("TEST 6 FAIL");
            fail_count = fail_count + 1;

        end


        // ========================================================
        // TEST 7
        // STATUS must be read-only
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 7: STATUS READ-ONLY PROTECTION");
        $display("========================================");

        axi_read(
            32'h00000004,
            status_before_write,
            read_resp
        );

        $display(
            "STATUS before illegal write = %h",
            status_before_write
        );

        axi_write(
            32'h00000004,
            32'hFFFFFFFF,
            4'b1111,
            write_resp
        );

        axi_read(
            32'h00000004,
            read_data,
            read_resp
        );

        $display(
            "STATUS after illegal write = %h",
            read_data
        );

        if ((write_resp == 2'b10) &&
            (read_resp  == 2'b00) &&
            (read_data  == status_before_write)) begin

            $display(
                "TEST 7 PASS: STATUS unchanged and SLVERR returned"
            );

            pass_count = pass_count + 1;

        end
        else begin

            $display(
                "TEST 7 FAIL: before=%h after=%h BRESP=%b",
                status_before_write,
                read_data,
                write_resp
            );

            fail_count = fail_count + 1;

        end


        // ========================================================
        // TEST 8
        // W DATA arrives BEFORE AW address
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 8: W BEFORE AW");
        $display("========================================");


        // Send W channel first
        @(negedge ACLK);

        WDATA  = 32'hCAFEBABE;
        WSTRB  = 4'b1111;
        WVALID = 1'b1;

        do begin
            @(posedge ACLK);
        end while (!WREADY);

        @(negedge ACLK);
        WVALID = 1'b0;


        // Deliberate delay
        repeat (3) @(posedge ACLK);


        // Now send AW channel
        @(negedge ACLK);

        AWADDR  = 32'h00000008;
        AWVALID = 1'b1;

        do begin
            @(posedge ACLK);
        end while (!AWREADY);

        @(negedge ACLK);
        AWVALID = 1'b0;


        // Accept response
        BREADY = 1'b1;

        do begin
            @(posedge ACLK);
        end while (!BVALID);

        write_resp = BRESP;

        @(negedge ACLK);
        BREADY = 1'b0;


        // Read CONFIG
        axi_read(
            32'h00000008,
            read_data,
            read_resp
        );

        if ((write_resp == 2'b00) &&
            (read_resp  == 2'b00) &&
            (read_data  == 32'hCAFEBABE)) begin

            $display(
                "TEST 8 PASS: W-before-AW handled correctly"
            );

            pass_count = pass_count + 1;

        end
        else begin

            $display(
                "TEST 8 FAIL: data=%h BRESP=%b",
                read_data,
                write_resp
            );

            fail_count = fail_count + 1;

        end


        // ========================================================
        // TEST 9
        // AW address arrives BEFORE W data, with delay
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 9: AW BEFORE DELAYED W");
        $display("========================================");


        // Send AW first
        @(negedge ACLK);

        AWADDR  = 32'h00000008;
AWVALID = 1'b1;

do begin
    @(posedge ACLK);
end while (!AWREADY);



@(negedge ACLK);
AWVALID = 1'b0;


        // Deliberate gap
        repeat (3) @(posedge ACLK);


        // Send W later
        @(negedge ACLK);

        WDATA  = 32'h12345678;
WSTRB  = 4'b1111;
WVALID = 1'b1;

do begin
    @(posedge ACLK);
end while (!WREADY);



@(negedge ACLK);
WVALID = 1'b0;


        // Accept B response
        BREADY = 1'b1;

        do begin
            @(posedge ACLK);
        end while (!BVALID);

        write_resp = BRESP;

        @(negedge ACLK);
        BREADY = 1'b0;


        // Read CONFIG
        axi_read(
            32'h00000008,
            read_data,
            read_resp
        );

        if ((write_resp == 2'b00) &&
            (read_resp  == 2'b00) &&
            (read_data  == 32'h12345678)) begin

            $display(
                "TEST 9 PASS: delayed W handled correctly"
            );

            pass_count = pass_count + 1;

        end
        else begin

            $display(
                "TEST 9 FAIL: data=%h BRESP=%b",
                read_data,
                write_resp
            );

            fail_count = fail_count + 1;

        end


        // ========================================================
        // TEST 10
        // B-channel backpressure
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 10: B-CHANNEL BACKPRESSURE");
        $display("========================================");


        // Keep master NOT READY for B response
        BREADY = 1'b0;


        // Send AW
        @(negedge ACLK);

        AWADDR  = 32'h00000008;
        AWVALID = 1'b1;

        do begin
            @(posedge ACLK);
        end while (!AWREADY);

        @(negedge ACLK);
        AWVALID = 1'b0;


        // Send W
        WDATA  = 32'hABCDEF12;
        WSTRB  = 4'b1111;
        WVALID = 1'b1;

        do begin
            @(posedge ACLK);
        end while (!WREADY);

        @(negedge ACLK);
        WVALID = 1'b0;


        // Wait for slave response
        do begin
            @(posedge ACLK);
        end while (!BVALID);

        write_resp = BRESP;


        // Hold backpressure for multiple cycles
        repeat (3) begin

            @(negedge ACLK);

            if ((BVALID !== 1'b1) ||
                (BRESP  !== write_resp)) begin

                $display(
                    "TEST 10 FAIL: B response changed during stall"
                );

                fail_count = fail_count + 1;
            end

        end


        // Finally accept response
        BREADY = 1'b1;

        @(posedge ACLK);
        @(negedge ACLK);

        BREADY = 1'b0;


        // Verify BVALID clears
        @(posedge ACLK);

        if (BVALID == 1'b0) begin

            // Verify actual write
            axi_read(
                32'h00000008,
                read_data,
                read_resp
            );

            if ((write_resp == 2'b00) &&
                (read_resp  == 2'b00) &&
                (read_data  == 32'hABCDEF12)) begin

                $display(
                    "TEST 10 PASS: BVALID/BRESP held during backpressure"
                );

                pass_count = pass_count + 1;

            end
            else begin

                $display("TEST 10 FAIL: write/readback mismatch");
                fail_count = fail_count + 1;
            end

        end
        else begin

            $display(
                "TEST 10 FAIL: BVALID did not clear after handshake"
            );

            fail_count = fail_count + 1;

        end


        // ========================================================
        // TEST 11
        // R-channel backpressure
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 11: R-CHANNEL BACKPRESSURE");
        $display("========================================");


        // Establish known CONFIG value
        axi_write(
            32'h00000008,
            32'h13579BDF,
            4'b1111,
            write_resp
        );


        // Master is ready before any read response exists.
// This exercises RVALID=0, RREADY=1.
RREADY = 1'b1;

@(posedge ACLK);

RREADY = 1'b0;


        // Send AR
        @(negedge ACLK);

        ARADDR  = 32'h00000008;
ARVALID = 1'b1;

do begin
    @(posedge ACLK);
end while (!ARREADY);

@(negedge ACLK);
ARVALID = 1'b0;


        // Wait for RVALID
        do begin
            @(posedge ACLK);
        end while (!RVALID);

        read_data = RDATA;
        read_resp = RRESP;


        // Stall response for multiple cycles
        repeat (3) begin

            @(negedge ACLK);

            if ((RVALID !== 1'b1) ||
                (RDATA  !== read_data) ||
                (RRESP  !== read_resp)) begin

                $display(
                    "TEST 11 FAIL: read response changed during stall"
                );

                fail_count = fail_count + 1;
            end

        end


        // Accept response
        RREADY = 1'b1;

        @(posedge ACLK);
        @(negedge ACLK);

        RREADY = 1'b0;


        // Give DUT one edge to reflect cleared RVALID
        @(posedge ACLK);


        if ((RVALID == 1'b0) &&
            (read_resp == 2'b00) &&
            (read_data == 32'h13579BDF)) begin

            $display(
                "TEST 11 PASS: RVALID/RDATA/RRESP stable during backpressure"
            );

            pass_count = pass_count + 1;

        end
        else begin

            $display(
                "TEST 11 FAIL: data=%h resp=%b RVALID=%b",
                read_data,
                read_resp,
                RVALID
            );

            fail_count = fail_count + 1;

        end


        // ========================================================
        // TEST 12
        // Reset and recovery
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 12: RESET AND RECOVERY");
        $display("========================================");


        // Put DUT into known non-zero state
        axi_write(
            32'h00000008,
            32'hAAAAAAAA,
            4'b1111,
            write_resp
        );

        axi_write(
            32'h0000000C,
            32'h00000001,
            4'b1111,
            write_resp
        );


        // --------------------------------------------------------
        // Assert synchronous active-low reset
        // --------------------------------------------------------

        @(negedge ACLK);
        ARESETn = 1'b0;

        repeat (2) @(posedge ACLK);

        @(negedge ACLK);
        ARESETn = 1'b1;

        repeat (2) @(posedge ACLK);


        // --------------------------------------------------------
        // Verify CONFIG reset
        // --------------------------------------------------------

        axi_read(
            32'h00000008,
            read_data,
            read_resp
        );

        if ((read_resp == 2'b00) &&
            (read_data == 32'h00000000)) begin

            $display("CONFIG RESET CHECK PASS");

        end
        else begin

            $display(
                "CONFIG RESET CHECK FAIL: %h",
                read_data
            );

            fail_count = fail_count + 1;

        end


        // --------------------------------------------------------
        // Verify IRQ_ENABLE reset
        // --------------------------------------------------------

        axi_read(
            32'h0000000C,
            read_data,
            read_resp
        );

        if ((read_resp == 2'b00) &&
            (read_data == 32'h00000000)) begin

            $display("IRQ_ENABLE RESET CHECK PASS");

        end
        else begin

            $display(
                "IRQ_ENABLE RESET CHECK FAIL: %h",
                read_data
            );

            fail_count = fail_count + 1;

        end


        // --------------------------------------------------------
        // Verify STATUS reset
        // --------------------------------------------------------

        axi_read(
            32'h00000004,
            read_data,
            read_resp
        );

        if ((read_resp == 2'b00) &&
            (read_data == 32'h00000000)) begin

            $display("STATUS RESET CHECK PASS");

        end
        else begin

            $display(
                "STATUS RESET CHECK FAIL: %h",
                read_data
            );

            fail_count = fail_count + 1;

        end


        // --------------------------------------------------------
        // Verify interface state
        // --------------------------------------------------------

        if ((BVALID == 1'b0) &&
            (RVALID == 1'b0)) begin

            $display("AXI RESPONSE STATE RESET CHECK PASS");

        end
        else begin

            $display(
                "AXI RESPONSE STATE RESET CHECK FAIL"
            );

            fail_count = fail_count + 1;

        end


        // --------------------------------------------------------
        // Recovery test
        // --------------------------------------------------------

        axi_write(
            32'h00000008,
            32'h55AA55AA,
            4'b1111,
            write_resp
        );

        axi_read(
            32'h00000008,
            read_data,
            read_resp
        );

        if ((write_resp == 2'b00) &&
            (read_resp  == 2'b00) &&
            (read_data  == 32'h55AA55AA)) begin

            $display(
                "TEST 12 PASS: DUT recovered after reset"
            );

            pass_count = pass_count + 1;

        end
        else begin

            $display(
                "TEST 12 FAIL: recovery read=%h",
                read_data
            );

            fail_count = fail_count + 1;

        end


        // ========================================================
        // FINAL SUMMARY
        // ========================================================

        $display("");
        $display("========================================");
        $display("DIRECTED TEST SUMMARY");
        $display("========================================");

        $display("Tests passed = %0d", pass_count);
        $display("Failures     = %0d", fail_count);

        if ((pass_count == 12) &&
            (fail_count == 0)) begin

            $display("");
            $display("ALL 12 DIRECTED TESTS PASSED");
            $display("");

        end
        else begin

            $display("");
            $display("DIRECTED REGRESSION HAS FAILURES");
            $display("");

        end

        $finish;

    end

endmodule
