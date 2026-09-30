class axi_lite_ral_test extends uvm_test;

    `uvm_component_utils(axi_lite_ral_test)

    axi_lite_env env;

    function new(
        string name = "axi_lite_ral_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        env = axi_lite_env::type_id::create(
            "env",
            this
        );

    endfunction


    task run_phase(uvm_phase phase);

        axi_lite_ral_sequence ral_seq;

        ral_seq =
            axi_lite_ral_sequence::type_id::create(
                "ral_seq"
            );

        ral_seq.regmodel = env.regmodel;

        phase.raise_objection(this);

        ral_seq.start(null);

        phase.drop_objection(this);

    endtask

endclass
