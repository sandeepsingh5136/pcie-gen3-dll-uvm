// ============================================================================
// Class: pcie_sequencer
// Description: Parameterized sequencer for pcie_seq_item transactions.
// ============================================================================

`ifndef PCIE_SEQUENCER_SV
`define PCIE_SEQUENCER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class pcie_sequencer extends uvm_sequencer #(pcie_seq_item);
    `uvm_component_utils(pcie_sequencer)

    function new(string name = "pcie_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

`endif