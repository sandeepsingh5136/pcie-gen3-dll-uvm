// ============================================================================
// Class: pcie_scoreboard
// Description: Collects monitored TLP packets, tracks pass/fail counters,
//              and validates transaction integrity.
// ============================================================================

`ifndef PCIE_SCOREBOARD_SV
`define PCIE_SCOREBOARD_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

`uvm_analysis_imp_decl(_mon)

class pcie_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(pcie_scoreboard)

    uvm_analysis_imp_mon #(pcie_seq_item, pcie_scoreboard) mon_export;

    int total_pkts_seen;
    int error_pkts_seen;
    int clean_pkts_seen;

    function new(string name = "pcie_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        mon_export = new("mon_export", this);
        total_pkts_seen = 0;
        error_pkts_seen = 0;
        clean_pkts_seen = 0;
    endfunction

    virtual function void write_mon(pcie_seq_item item);
        total_pkts_seen++;

        if (item.corrupt_crc || item.corrupt_seq) begin
            error_pkts_seen++;
            `uvm_info("SCB_INJECT", $sformatf("Monitored Packet #%0d had error flags asserted.", total_pkts_seen), UVM_MEDIUM)
        end else begin
            clean_pkts_seen++;
            `uvm_info("SCB_VALID", $sformatf("Monitored Clean Packet #%0d with size %0d bytes.", total_pkts_seen, item.payload.size()), UVM_HIGH)
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB_FINAL", "==================================================", UVM_NONE)
        `uvm_info("SCB_FINAL", $sformatf(" [SCOREBOARD REPORT] Total TLPs Sampled: %0d", total_pkts_seen), UVM_NONE)
        `uvm_info("SCB_FINAL", $sformatf("                     Clean Packets     : %0d", clean_pkts_seen), UVM_NONE)
        `uvm_info("SCB_FINAL", $sformatf("                     Injected Errors   : %0d", error_pkts_seen), UVM_NONE)
        `uvm_info("SCB_FINAL", "==================================================", UVM_NONE)
    endfunction

endclass

`endif