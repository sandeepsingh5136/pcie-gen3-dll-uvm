// ============================================================================
// Class: pcie_basic_sequence & pcie_error_injection_sequence
// Description: Sequences generating stimulus streams for the driver.
// ============================================================================

`ifndef PCIE_SEQUENCE_SV
`define PCIE_SEQUENCE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

// Base Sequence: Standard valid packets
class pcie_basic_sequence extends uvm_sequence #(pcie_seq_item);
    `uvm_object_utils(pcie_basic_sequence)

    rand int num_packets;

    constraint c_num_pkts {
        num_packets inside {[5:15]};
    }

    function new(string name = "pcie_basic_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("SEQ", $sformatf("Starting basic sequence with %0d packets", num_packets), UVM_LOW)

        for (int i = 0; i < num_packets; i++) begin
            req = pcie_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with { corrupt_crc == 0; corrupt_seq == 0; }) begin
                `uvm_error("SEQ", "Randomization failed for valid TLP packet!")
            end
            finish_item(req);
        end
    endtask
endclass

// Error Injection Sequence: Testing NAK & Retransmission Recovery
class pcie_error_injection_sequence extends uvm_sequence #(pcie_seq_item);
    `uvm_object_utils(pcie_error_injection_sequence)

    rand int num_packets;

    constraint c_num_pkts {
        num_packets inside {[10:20]};
    }

    function new(string name = "pcie_error_injection_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("ERR_SEQ", $sformatf("Starting error-injection sequence with %0d packets", num_packets), UVM_LOW)

        for (int i = 0; i < num_packets; i++) begin
            req = pcie_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize()) begin
                `uvm_error("ERR_SEQ", "Randomization failed for error packet!")
            end
            finish_item(req);
        end
    endtask
endclass

`endif