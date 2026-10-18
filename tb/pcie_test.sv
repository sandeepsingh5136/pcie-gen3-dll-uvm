// ============================================================================
// Class: pcie_test
// Description: Instantiates testbench environment and drives verification sequences.
// ============================================================================

`ifndef PCIE_TEST_SV
`define PCIE_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class pcie_test extends uvm_test;
    `uvm_component_utils(pcie_test)

    pcie_env env;

    function new(string name = "pcie_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = pcie_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        pcie_basic_sequence seq;
        seq = pcie_basic_sequence::type_id::create("seq");

        phase.raise_objection(this, "Starting PCIe Verification Sequence");
        `uvm_info("TEST", "Starting pcie_basic_sequence...", UVM_LOW)

        seq.start(env.agent.sequencer);

        #500ns; // Allow pipeline drainage and final handshake checks
        `uvm_info("TEST", "PCIe Sequence Completed.", UVM_LOW)
        phase.drop_objection(this, "Completed PCIe Verification Sequence");
    endtask

endclass

`endif