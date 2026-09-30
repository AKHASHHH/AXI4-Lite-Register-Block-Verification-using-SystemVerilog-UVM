class axi_lite_smoke_sequence extends uvm_sequence #(axi_lite_seq_item);
 `uvm_object_utils(axi_lite_smoke_sequence)
 
 function new(string name = "axi_lite_smoke_sequence");
  super.new(name);
 endfunction
  
  task body();
    axi_lite_seq_item req;
    req = axi_lite_seq_item::type_id::create("write_req");
    start_item(req);
    req.operation = AXI_WRITE;
    req.addr      = 32'h00000008;
    req.data      = 32'hDEADBEEF;
    req.strb      = 4'b1111;
    finish_item(req);
    
    req = axi_lite_seq_item::type_id::create("read_req");
    start_item(req);
    req.operation = AXI_READ;
    req.addr = 32'h00000008;
    req.data = 32'h00000000;
    req.strb = 4'b0000;
    finish_item(req);
    
  endtask
   
 
 
endclass

class axi_lite_base_sequence extends uvm_sequence #(axi_lite_seq_item);

    `uvm_object_utils(axi_lite_base_sequence)

    function new(string name = "axi_lite_base_sequence");
        super.new(name);
    endfunction

    task body();

        axi_lite_seq_item req;
        
       repeat (500) begin

        req = axi_lite_seq_item::type_id::create("req");

        start_item(req);

        assert(req.randomize());

        finish_item(req);
        
       end

    endtask

endclass

class axi_lite_negative_sequence extends uvm_sequence #(axi_lite_seq_item);

    `uvm_object_utils(axi_lite_negative_sequence)

    function new(string name = "axi_lite_negative_sequence");
        super.new(name);
    endfunction

    task body();

        axi_lite_seq_item req;


        // =====================================================
        // Negative Test 1
        // WRITE to read-only STATUS register (0x04)
        // Expected: BRESP = SLVERR (2'b10)
        // =====================================================

        req = axi_lite_seq_item::type_id::create("status_write_req");

        start_item(req);

        req.operation = AXI_WRITE;
        req.addr      = 32'h00000004;
        req.data      = 32'hDEADBEEF;
        req.strb      = 4'b1111;

        finish_item(req);


        // =====================================================
        // Negative Test 2
        // WRITE to invalid address (0x10)
        // Expected: BRESP = SLVERR (2'b10)
        // =====================================================

        req = axi_lite_seq_item::type_id::create("invalid_write_req");

        start_item(req);

        req.operation = AXI_WRITE;
        req.addr      = 32'h00000010;
        req.data      = 32'hCAFEBABE;
        req.strb      = 4'b1111;

        finish_item(req);


        // =====================================================
        // Negative Test 3
        // READ from invalid address (0x10)
        // Expected:
        // RRESP = SLVERR (2'b10)
        // RDATA = 0
        // =====================================================

        req = axi_lite_seq_item::type_id::create("invalid_read_req");

        start_item(req);

        req.operation = AXI_READ;
        req.addr      = 32'h00000010;
        req.data      = 32'h00000000;
        req.strb      = 4'b0000;

        finish_item(req);

    endtask

endclass


class axi_lite_wstrb_sequence extends uvm_sequence #(axi_lite_seq_item);

    `uvm_object_utils(axi_lite_wstrb_sequence)

    function new(string name = "axi_lite_wstrb_sequence");
        super.new(name);
    endfunction

    task body();

        axi_lite_seq_item req;

        for (int i = 0; i < 16; i++) begin

            req = axi_lite_seq_item::type_id::create(
                      $sformatf("wstrb_req_%0d", i));

            start_item(req);

            req.operation = AXI_WRITE;
            req.addr      = 32'h00000008;
            req.data      = 32'hA5A5A5A5;
            req.strb      = i[3:0];

            finish_item(req);

        end

    endtask

endclass
