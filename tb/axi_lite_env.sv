class axi_lite_env extends uvm_env;

    `uvm_component_utils(axi_lite_env)

    axi_lite_agent agent;
    axi_lite_scoreboard scoreboard;
    axi_lite_coverage coverage;

    axi_lite_reg_block regmodel;
    axi_lite_reg_adapter adapter;
    uvm_reg_predictor #(axi_lite_seq_item) predictor;


    function new(
        string name = "axi_lite_env",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        agent =
            axi_lite_agent::type_id::create(
                "agent", this);

        scoreboard =
            axi_lite_scoreboard::type_id::create(
                "scoreboard", this);

        coverage =
            axi_lite_coverage::type_id::create(
                "coverage", this);


        regmodel =
            axi_lite_reg_block::type_id::create(
                "regmodel");

        regmodel.build();


        adapter =
            axi_lite_reg_adapter::type_id::create(
                "adapter");


        predictor =
            uvm_reg_predictor #(axi_lite_seq_item)::type_id::create(
                "predictor", this);


        predictor.map =
            regmodel.reg_map;

        predictor.adapter =
            adapter;

    endfunction


    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);


        agent.monitor.ap.connect(
            scoreboard.analysis_imp);

        agent.monitor.ap.connect(
            coverage.analysis_export);

        agent.monitor.ap.connect(
            predictor.bus_in);


        regmodel.reg_map.set_sequencer(
            agent.sequencer,
            adapter
        );

        regmodel.reg_map.set_auto_predict(0);

    endfunction

endclass
