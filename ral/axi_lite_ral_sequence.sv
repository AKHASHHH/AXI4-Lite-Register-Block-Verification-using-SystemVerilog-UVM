class axi_lite_ral_sequence extends uvm_sequence;

    `uvm_object_utils(axi_lite_ral_sequence)

    axi_lite_reg_block regmodel;


    function new(string name = "axi_lite_ral_sequence");
        super.new(name);
    endfunction


    task body();

        uvm_status_e    status;
        uvm_reg_data_t data;
        uvm_reg_data_t mirrored_data;


        // ============================================================
        // TEST 1: CONFIG WRITE
        // ============================================================

        regmodel.CONFIG.write(
            status,
            32'h12345678,
            UVM_FRONTDOOR
        );

        if (status != UVM_IS_OK)
            `uvm_error(
                "RAL_SEQ",
                "CONFIG write failed"
            )


        // ============================================================
        // TEST 2: CHECK CONFIG MIRRORED VALUE
        // ============================================================

        mirrored_data = regmodel.CONFIG.get_mirrored_value();

        if (mirrored_data != 32'h12345678)
            `uvm_error(
                "RAL_SEQ",
                $sformatf(
                    "CONFIG mirror mismatch: expected=0x%08h mirrored=0x%08h",
                    32'h12345678,
                    mirrored_data
                )
            )
        else
            `uvm_info(
                "RAL_SEQ",
                $sformatf(
                    "CONFIG mirror updated correctly: 0x%08h",
                    mirrored_data
                ),
                UVM_LOW
            )


        // ============================================================
        // TEST 3: CONFIG READBACK
        // ============================================================

        regmodel.CONFIG.read(
            status,
            data,
            UVM_FRONTDOOR
        );

        if (status != UVM_IS_OK)
            `uvm_error(
                "RAL_SEQ",
                "CONFIG read failed"
            )

        if (data != 32'h12345678)
            `uvm_error(
                "RAL_SEQ",
                $sformatf(
                    "CONFIG mismatch: expected=0x%08h actual=0x%08h",
                    32'h12345678,
                    data
                )
            )
        else
            `uvm_info(
                "RAL_SEQ",
                $sformatf(
                    "CONFIG RAL readback passed: 0x%08h",
                    data
                ),
                UVM_LOW
            )


        // ============================================================
        // TEST 4: IRQ_ENABLE WRITE
        // ============================================================

        regmodel.IRQ_ENABLE.write(
            status,
            32'h00000001,
            UVM_FRONTDOOR
        );

        if (status != UVM_IS_OK)
            `uvm_error(
                "RAL_SEQ",
                "IRQ_ENABLE write failed"
            )


        // ============================================================
        // TEST 5: IRQ_ENABLE READBACK
        // ============================================================

        regmodel.IRQ_ENABLE.read(
            status,
            data,
            UVM_FRONTDOOR
        );

        if (status != UVM_IS_OK)
            `uvm_error(
                "RAL_SEQ",
                "IRQ_ENABLE read failed"
            )

        if (data != 32'h00000001)
            `uvm_error(
                "RAL_SEQ",
                $sformatf(
                    "IRQ_ENABLE mismatch: expected=0x00000001 actual=0x%08h",
                    data
                )
            )
        else
            `uvm_info(
                "RAL_SEQ",
                $sformatf(
                    "IRQ_ENABLE RAL readback passed: 0x%08h",
                    data
                ),
                UVM_LOW
            )


        // ============================================================
        // TEST 6: STATUS READ
        // STATUS is read-only and contains volatile fields.
        // ============================================================

        regmodel.STATUS.read(
            status,
            data,
            UVM_FRONTDOOR
        );

        if (status != UVM_IS_OK)
            `uvm_error(
                "RAL_SEQ",
                "STATUS read failed"
            )
        else
            `uvm_info(
                "RAL_SEQ",
                $sformatf(
                    "STATUS RAL read passed: 0x%08h",
                    data
                ),
                UVM_LOW
            )


        // ============================================================
        // TEST 7: CONTROL.START WRITE
        // Writing START=1 begins the DUT operation.
        // START is expected to self-clear.
        // ============================================================

        regmodel.CONTROL.write(
            status,
            32'h00000001,
            UVM_FRONTDOOR
        );

        if (status != UVM_IS_OK)
            `uvm_error(
                "RAL_SEQ",
                "CONTROL START write failed"
            )


        // ============================================================
        // TEST 8: VERIFY CONTROL.START SELF-CLEAR
        // ============================================================

        regmodel.CONTROL.read(
            status,
            data,
            UVM_FRONTDOOR
        );

        if (status != UVM_IS_OK)
            `uvm_error(
                "RAL_SEQ",
                "CONTROL read failed"
            )

        if (data[0] != 1'b0)
            `uvm_error(
                "RAL_SEQ",
                $sformatf(
                    "CONTROL.START did not self-clear: CONTROL=0x%08h",
                    data
                )
            )
        else
            `uvm_info(
                "RAL_SEQ",
                $sformatf(
                    "CONTROL.START self-clear verified: CONTROL=0x%08h",
                    data
                ),
                UVM_LOW
            )


        // ============================================================
        // TEST 9: READ STATUS AFTER START
        // BUSY/DONE/ERROR are hardware-controlled volatile fields.
        // We observe the value without requiring a timing-dependent
        // exact BUSY/DONE state here.
        // ============================================================

        regmodel.STATUS.read(
            status,
            data,
            UVM_FRONTDOOR
        );

        if (status != UVM_IS_OK)
            `uvm_error(
                "RAL_SEQ",
                "STATUS read after START failed"
            )
        else
            `uvm_info(
                "RAL_SEQ",
                $sformatf(
                    "STATUS after START = 0x%08h",
                    data
                ),
                UVM_LOW
            )


        // ============================================================
        // RAL TEST COMPLETE
        // ============================================================

        `uvm_info(
            "RAL_SEQ",
            "AXI-Lite RAL sequence completed",
            UVM_LOW
        )

    endtask

endclass
