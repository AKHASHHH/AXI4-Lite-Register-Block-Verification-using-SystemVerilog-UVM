class axi_lite_coverage extends uvm_subscriber #(axi_lite_seq_item);

    `uvm_component_utils(axi_lite_coverage)

    axi_lite_seq_item tr;


    covergroup axi_lite_cg;

        cp_operation : coverpoint tr.operation {
            bins read  = {AXI_READ};
            bins write = {AXI_WRITE};
        }

        cp_addr : coverpoint tr.addr {
            bins control    = {32'h00000000};
            bins status     = {32'h00000004};
            bins config     = {32'h00000008};
            bins irq_enable = {32'h0000000C};
            bins invalid    = default;
        }

        cp_resp : coverpoint tr.resp {
            bins okay   = {2'b00};
            bins slverr = {2'b10};
        }

        cp_strb : coverpoint tr.strb {
            bins strb_values[] = {[4'b0000:4'b1111]};
        }

        operation_x_addr : cross cp_operation, cp_addr;

    endgroup


    function new(string name = "axi_lite_coverage",
                 uvm_component parent = null);

        super.new(name, parent);

        axi_lite_cg = new();

    endfunction


    function void write(axi_lite_seq_item t);

        tr = t;

        axi_lite_cg.sample();

    endfunction

endclass
