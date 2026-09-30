class axi_lite_control_reg extends uvm_reg;

    `uvm_object_utils(axi_lite_control_reg)

    uvm_reg_field START;

    function new(string name = "CONTROL");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();

        START = uvm_reg_field::type_id::create("START");

        START.configure(
            this,
            1,
            0,
            "RW",
            0,
            1'b0,
            1,
            1,
            0
        );

    endfunction

endclass


class axi_lite_status_reg extends uvm_reg;

    `uvm_object_utils(axi_lite_status_reg)

    uvm_reg_field BUSY;
    uvm_reg_field DONE;
    uvm_reg_field ERROR;

    function new(string name = "STATUS");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();

        BUSY = uvm_reg_field::type_id::create("BUSY");
        DONE = uvm_reg_field::type_id::create("DONE");
        ERROR = uvm_reg_field::type_id::create("ERROR");

        BUSY.configure(
            this,
            1,
            0,
            "RO",
            1,
            1'b0,
            1,
            0,
            0
        );

        DONE.configure(
            this,
            1,
            1,
            "RO",
            1,
            1'b0,
            1,
            0,
            0
        );

        ERROR.configure(
            this,
            1,
            2,
            "RO",
            1,
            1'b0,
            1,
            0,
            0
        );

    endfunction

endclass


class axi_lite_config_reg extends uvm_reg;

    `uvm_object_utils(axi_lite_config_reg)

    uvm_reg_field VALUE;

    function new(string name = "CONFIG");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();

        VALUE = uvm_reg_field::type_id::create("VALUE");

        VALUE.configure(
            this,
            32,
            0,
            "RW",
            0,
            32'h00000000,
            1,
            1,
            0
        );

    endfunction

endclass


class axi_lite_irq_enable_reg extends uvm_reg;

    `uvm_object_utils(axi_lite_irq_enable_reg)

    uvm_reg_field VALUE;

    function new(string name = "IRQ_ENABLE");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();

        VALUE = uvm_reg_field::type_id::create("VALUE");

        VALUE.configure(
            this,
            32,
            0,
            "RW",
            0,
            32'h00000000,
            1,
            1,
            0
        );

    endfunction

endclass


class axi_lite_reg_block extends uvm_reg_block;

    `uvm_object_utils(axi_lite_reg_block)

    rand axi_lite_control_reg    CONTROL;
    rand axi_lite_status_reg     STATUS;
    rand axi_lite_config_reg     CONFIG;
    rand axi_lite_irq_enable_reg IRQ_ENABLE;

    uvm_reg_map reg_map;

    function new(string name = "axi_lite_reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();

        CONTROL =
            axi_lite_control_reg::type_id::create("CONTROL");

        STATUS =
            axi_lite_status_reg::type_id::create("STATUS");

        CONFIG =
            axi_lite_config_reg::type_id::create("CONFIG");

        IRQ_ENABLE =
            axi_lite_irq_enable_reg::type_id::create("IRQ_ENABLE");


        CONTROL.configure(this);
        STATUS.configure(this);
        CONFIG.configure(this);
        IRQ_ENABLE.configure(this);


        CONTROL.build();
        STATUS.build();
        CONFIG.build();
        IRQ_ENABLE.build();


        reg_map = create_map(
            "reg_map",
            0,
            4,
            UVM_LITTLE_ENDIAN
        );


        reg_map.add_reg(CONTROL,    'h00, "RW");
        reg_map.add_reg(STATUS,     'h04, "RO");
        reg_map.add_reg(CONFIG,     'h08, "RW");
        reg_map.add_reg(IRQ_ENABLE, 'h0C, "RW");


        lock_model();

    endfunction

endclass
