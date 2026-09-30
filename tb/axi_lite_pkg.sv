package axi_lite_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "axi_lite_seq_item.sv"
    `include "axi_lite_sequence.sv"
    `include "axi_lite_sequencer.sv"
    `include "axi_lite_driver.sv"
    `include "axi_lite_monitor.sv"
    `include "axi_lite_scoreboard.sv"
    `include "axi_lite_agent.sv"
    `include "axi_lite_coverage.sv"
    `include "../ral/axi_lite_reg_model.sv"
    `include "../ral/axi_lite_reg_adapter.sv"
    `include "../ral/axi_lite_ral_sequence.sv"
    `include "axi_lite_env.sv"
    `include "axi_lite_test.sv"
    `include "axi_lite_ral_test.sv"

endpackage
