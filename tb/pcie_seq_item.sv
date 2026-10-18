// ============================================================================
// Class: pcie_seq_item
// Description: UVM Sequence Item modeling randomized PCIe TLPs and
//              error injection knobs for verification closure.
// ============================================================================

`ifndef PCIE_SEQ_ITEM_SV
`define PCIE_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class pcie_seq_item extends uvm_sequence_item;

    // Payload byte stream
    rand bit [7:0] payload[];

    // Error injection knobs for corner-case verification
    rand bit       corrupt_crc;
    rand bit       corrupt_seq;
    rand bit       inject_stall;

    // Constraints
    constraint c_payload_len {
        payload.size() inside {[4:32]}; // Typical small TLP packet sizes
    }

    // Weight distribution: 85% normal traffic, 15% error injection
    constraint c_crc_error_dist {
        corrupt_crc dist {0 := 85, 1 := 15};
    }

    constraint c_seq_error_dist {
        corrupt_seq dist {0 := 95, 1 := 5};
    }

    `uvm_object_utils_begin(pcie_seq_item)
        `uvm_field_array_int(payload,      UVM_ALL_ON)
        `uvm_field_int      (corrupt_crc,  UVM_ALL_ON)
        `uvm_field_int      (corrupt_seq,  UVM_ALL_ON)
        `uvm_field_int      (inject_stall, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "pcie_seq_item");
        super.new(name);
    endfunction

endclass

`endif