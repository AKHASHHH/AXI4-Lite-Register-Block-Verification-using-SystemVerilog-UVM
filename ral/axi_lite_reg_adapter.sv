class axi_lite_reg_adapter extends uvm_reg_adapter;

    `uvm_object_utils(axi_lite_reg_adapter)

    function new(string name = "axi_lite_reg_adapter");
        super.new(name);
    endfunction


    virtual function uvm_sequence_item reg2bus(
        const ref uvm_reg_bus_op rw
    );

        axi_lite_seq_item tr;

        tr = axi_lite_seq_item::type_id::create("tr");

        tr.addr = rw.addr;
        tr.data = rw.data;

        if (rw.kind == UVM_WRITE) begin

            tr.operation = AXI_WRITE;
            tr.strb      = 4'b1111;

        end
        else begin

            tr.operation = AXI_READ;
            tr.strb      = 4'b0000;

        end

        return tr;

    endfunction


    virtual function void bus2reg(
        uvm_sequence_item bus_item,
        ref uvm_reg_bus_op rw
    );

        axi_lite_seq_item tr;

        if (!$cast(tr, bus_item)) begin
            `uvm_fatal(
                "RAL_ADAPTER",
                "bus_item is not an axi_lite_seq_item"
            )
        end

        if (tr.operation == AXI_WRITE)
            rw.kind = UVM_WRITE;
        else
            rw.kind = UVM_READ;

        rw.addr = tr.addr;
        rw.data = tr.data;

        if (tr.resp == 2'b00)
            rw.status = UVM_IS_OK;
        else
            rw.status = UVM_NOT_OK;

    endfunction

endclass
