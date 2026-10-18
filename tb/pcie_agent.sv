// ============================================================================
// Class: pcie_agent
// Description: Encapsulates Sequencer, Driver, and Monitor into a standard
//              UVM verification component.
// ============================================================================

`ifndef PCIE_AGENT_SV
`define PCIE_AGENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class pcie_agent extends uvm_agent;
    `uvm_component_utils(pcie_agent)

    pcie_sequencer sequencer;
    pcie_driver    driver;
    pcie_monitor   monitor;

    function new(string name = "pcie_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Always instantiate the monitor
        monitor = pcie_monitor::type_id::create("monitor", this);

        // Instantiate driver and sequencer only if active agent
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = pcie_sequencer::type_id::create("sequencer", this);
            driver    = pcie_driver::type_id::create("driver", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass

`endif