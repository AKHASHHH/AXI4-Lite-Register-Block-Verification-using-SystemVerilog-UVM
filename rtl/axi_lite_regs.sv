`timescale 1ns/1ps

module axi_lite_regs (

    // -----------------------------------------------------
    // Clock and reset
    // -----------------------------------------------------
    input  logic        ACLK,
    input  logic        ARESETn,

    // -----------------------------------------------------
    // AXI-Lite write address channel
    // -----------------------------------------------------
    input  logic [31:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,

    // -----------------------------------------------------
    // AXI-Lite write data channel
    // -----------------------------------------------------
    input  logic [31:0] WDATA,
    input  logic [3:0]  WSTRB,
    input  logic        WVALID,
    output logic        WREADY,

    // -----------------------------------------------------
    // AXI-Lite write response channel
    // -----------------------------------------------------
    output logic [1:0]  BRESP,
    output logic        BVALID,
    input  logic        BREADY,

    // -----------------------------------------------------
    // AXI-Lite read address channel
    // -----------------------------------------------------
    input  logic [31:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,

    // -----------------------------------------------------
    // AXI-Lite read data channel
    // -----------------------------------------------------
    output logic [31:0] RDATA,
    output logic [1:0]  RRESP,
    output logic        RVALID,
    input  logic        RREADY

);


// =========================================================
// Internal registers
// =========================================================

// Software-visible registers
logic [31:0] control_reg;
logic [31:0] config_reg;
logic [31:0] irq_enable_reg;


// ---------------------------------------------------------
// Captured AXI write information
// ---------------------------------------------------------

logic [31:0] awaddr_reg;
logic [31:0] wdata_reg;
logic [3:0]  wstrb_reg;

logic aw_pending;
logic w_pending;


// ---------------------------------------------------------
// Hardware status signals
// ---------------------------------------------------------

logic busy;
logic done;
logic error;


// Combined 32-bit STATUS register value
logic [31:0] status_value;


// Counter used to model a simple hardware operation
logic [2:0] operation_count;


// =========================================================
// STATUS register construction
// =========================================================
//
// STATUS register:
// bit [0] = BUSY
// bit [1] = DONE
// bit [2] = ERROR
// bits [31:3] = 0
//

assign status_value = {
    29'b0,
    error,
    done,
    busy
};


// =========================================================
// AXI-Lite READY logic
// =========================================================

// Accept another write address only if one is not
// already stored.
assign AWREADY = !aw_pending;

// Accept another write-data transfer only if one is
// not already stored.
assign WREADY = !w_pending;

// Accept another read address only when we are not
// already holding a read response.
assign ARREADY = !RVALID;


// =========================================================
// Write-strobe helper function
// =========================================================
//
// Each WSTRB bit controls one byte of the 32-bit register.
//
// WSTRB[0] -> bits [7:0]
// WSTRB[1] -> bits [15:8]
// WSTRB[2] -> bits [23:16]
// WSTRB[3] -> bits [31:24]
//

function automatic logic [31:0] apply_wstrb (

    input logic [31:0] old_value,
    input logic [31:0] new_value,
    input logic [3:0]  strb

);

    logic [31:0] result;

    begin

        // Preserve the current value by default.
        result = old_value;


        // Byte 0
        if (strb[0]) begin
            result[7:0] = new_value[7:0];
        end


        // Byte 1
        if (strb[1]) begin
            result[15:8] = new_value[15:8];
        end


        // Byte 2
        if (strb[2]) begin
            result[23:16] = new_value[23:16];
        end


        // Byte 3
        if (strb[3]) begin
            result[31:24] = new_value[31:24];
        end


        return result;

    end

endfunction


// =========================================================
// Main sequential logic
// =========================================================

always_ff @(posedge ACLK) begin


    // ===================================================== 
    // Synchronous active-low reset
    // =====================================================

    if (!ARESETn) begin


        // -------------------------------------------------
        // Reset software-visible registers
        // -------------------------------------------------

        control_reg    <= 32'h00000000;
        config_reg     <= 32'h00000000;
        irq_enable_reg <= 32'h00000000;


        // -------------------------------------------------
        // Reset captured AXI write information
        // -------------------------------------------------

        awaddr_reg <= 32'h00000000;
        wdata_reg  <= 32'h00000000;
        wstrb_reg  <= 4'b0000;

        aw_pending <= 1'b0;
        w_pending  <= 1'b0;


        // -------------------------------------------------
        // Reset AXI write response channel
        // -------------------------------------------------

        BRESP  <= 2'b00;
        BVALID <= 1'b0;


        // -------------------------------------------------
        // Reset AXI read response channel
        // -------------------------------------------------

        RDATA  <= 32'h00000000;
        RRESP  <= 2'b00;
        RVALID <= 1'b0;


        // -------------------------------------------------
        // Reset hardware state
        // -------------------------------------------------

        busy            <= 1'b0;
        done            <= 1'b0;
        error           <= 1'b0;
        operation_count <= 3'd0;

    end


    // =====================================================
    // Normal operation
    // =====================================================

    else begin
    

        // =================================================
        // 1. Capture AXI-Lite write address
        // =================================================

        if (AWVALID && AWREADY) begin

            awaddr_reg <= AWADDR;
            aw_pending <= 1'b1;

        end


        // =================================================
        // 2. Capture AXI-Lite write data
        // =================================================

        if (WVALID && WREADY) begin

            wdata_reg <= WDATA;
            wstrb_reg <= WSTRB;
            w_pending <= 1'b1;

        end


        // =================================================
        // 3. Process complete AXI-Lite write
        // =================================================
        //
        // We only process the write once BOTH:
        //
        //      aw_pending = 1
        //      w_pending  = 1
        //
        // and there is no previous B response waiting.
        //

        if (aw_pending && w_pending && !BVALID) begin


            // Assume the write is successful.
            BRESP <= 2'b00;


            // ---------------------------------------------
            // Decode write address
            // ---------------------------------------------

            case (awaddr_reg)


                // -----------------------------------------
                // CONTROL register
                // Address: 0x00
                // Access: R/W
                // -----------------------------------------

                32'h00000000: begin

                    control_reg <= apply_wstrb(
                        control_reg,
                        wdata_reg,
                        wstrb_reg
                    );

                end


                // -----------------------------------------
                // CONFIG register
                // Address: 0x08
                // Access: R/W
                // -----------------------------------------

                32'h00000008: begin

                    config_reg <= apply_wstrb(
                        config_reg,
                        wdata_reg,
                        wstrb_reg
                    );

                end


                // -----------------------------------------
                // IRQ_ENABLE register
                // Address: 0x0C
                // Access: R/W
                // -----------------------------------------

                32'h0000000C: begin

                    irq_enable_reg <= apply_wstrb(
                        irq_enable_reg,
                        wdata_reg,
                        wstrb_reg
                    );

                end


                // -----------------------------------------
                // Invalid or non-writable address
                //
                // This also catches STATUS @ 0x04 because
                // STATUS is read-only.
                // -----------------------------------------

                default: begin

                    BRESP <= 2'b10;   // SLVERR

                end


            endcase


            // A valid write response is now available.
            BVALID <= 1'b1;


            // The captured address and data have now
            // been consumed.
            aw_pending <= 1'b0;
            w_pending  <= 1'b0;

        end


        // =================================================
        // 4. Complete AXI-Lite write response
        // =================================================
        //
        // BVALID = slave has a valid response
        // BREADY = master is ready for the response
        //

        if (BVALID && BREADY) begin

            BVALID <= 1'b0;

        end


        // =================================================
        // 5. Process AXI-Lite read
        // =================================================

        if (ARVALID && ARREADY) begin


            // Assume successful read.
            RRESP <= 2'b00;


            // ---------------------------------------------
            // Decode read address
            // ---------------------------------------------

            case (ARADDR)


                // -----------------------------------------
                // CONTROL register
                // Address: 0x00
                // -----------------------------------------

                32'h00000000: begin

                    RDATA <= control_reg;

                end


                // -----------------------------------------
                // STATUS register
                // Address: 0x04
                // -----------------------------------------

                32'h00000004: begin

                    RDATA <= status_value;

                end


                // -----------------------------------------
                // CONFIG register
                // Address: 0x08
                // -----------------------------------------

                32'h00000008: begin

                    RDATA <= config_reg;

                end


                // -----------------------------------------
                // IRQ_ENABLE register
                // Address: 0x0C
                // -----------------------------------------

                32'h0000000C: begin

                    RDATA <= irq_enable_reg;

                end


                // -----------------------------------------
                // Invalid read address
                // -----------------------------------------

                default: begin

                    RDATA <= 32'h00000000;
                    RRESP <= 2'b10;   // SLVERR

                end


            endcase


            // The read data and response are now valid.
            RVALID <= 1'b1;

        end
        

        // =================================================
        // 6. Complete AXI-Lite read response
        // =================================================
        //
        // RVALID = slave has valid read data/response
        // RREADY = master is ready to accept it
        //

        if (RVALID && RREADY) begin

            RVALID <= 1'b0;

        end


        // =================================================
        // 7. Start simple hardware operation
        // =================================================
        //
        // CONTROL[0] is our START command bit.
        //
        // When:
        //
        //      CONTROL[0] = 1
        //      busy       = 0
        //
        // start the operation.
        //

        if (control_reg[0] && !busy) begin


            // Hardware is now busy.
            busy <= 1'b1;


            // Clear previous completion/error status.
            done  <= 1'b0;
            error <= 1'b0;


            // Our fake operation lasts four cycles.
            operation_count <= 3'd4;


            // START is a self-clearing command bit.
            control_reg[0] <= 1'b0;

        end


        // =================================================
        // 8. Hardware operation countdown
        // =================================================

        if (busy) begin


            // ---------------------------------------------
            // Operation still has cycles remaining
            // ---------------------------------------------

            if (operation_count > 3'd1) begin

                operation_count <= operation_count - 1'b1;

            end


            // ---------------------------------------------
            // Operation has completed
            // ---------------------------------------------

            else begin

                operation_count <= 3'd0;

                busy <= 1'b0;
                done <= 1'b1;

            end


        end


    end

end


endmodule
