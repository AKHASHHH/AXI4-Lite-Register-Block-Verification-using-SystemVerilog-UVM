`include "uvm_macros.svh"
import uvm_pkg::*;

typedef enum {
    AXI_READ,
    AXI_WRITE
} axi_op_t;

class axi_lite_seq_item extends uvm_sequence_item;

    rand axi_op_t operation;
    rand logic [31:0] addr;
    rand logic [3:0] strb;
    rand logic [31:0] data;

    logic [1:0] resp;

    `uvm_object_utils(axi_lite_seq_item)

    constraint valid_addr_c {
        addr inside {32'h00, 32'h04, 32'h08, 32'h0C};
    }

    constraint write_addr_c {
        if (operation == AXI_WRITE)
            addr != 32'h04;
    }

    function new(string name = "axi_lite_seq_item");
        super.new(name);
    endfunction

endclass
