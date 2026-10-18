// ============================================================================
// Class: pcie_monitor
// Description: Passively samples the bus interface, reconstructs TLP packets
//              and DLLP feedback, and broadcasts items to the scoreboard.
// ============================================================================

`ifndef PCIE_MONITOR_SV
`define PCIE_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class pcie_monitor extends uvm_monitor;
    `uvm_component_utils(pcie_monitor)

    virtual pcie_if vif;
    uvm_analysis_port #(pcie_seq_item) mon_ap;

    function new(string name = "pcie_monitor", uvm_component parent = null);
        super.new(name, parent);
        mon_ap = new("mon_ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual pcie_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON_CFG_ERR", "Virtual interface not found in uvm_config_db!")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        pcie_seq_item item;
        logic [7:0] captured_payload[$];

        @(posedge vif.rst_n);

        forever begin
            @(vif.mon_cb);

            // Collect outgoing TLP transactions from the TX side
            if (vif.mon_cb.tlp_tx_valid && vif.mon_cb.tlp_tx_ready) begin
                if (vif.mon_cb.tlp_tx_sop) begin
                    captured_payload.delete();
                end

                captured_payload.push_back(vif.mon_cb.tlp_tx_data);

                if (vif.mon_cb.tlp_tx_eop) begin
                    item = pcie_seq_item::type_id::create("mon_item");
                    item.payload = new[captured_payload.size()];
                    for (int i = 0; i < captured_payload.size(); i++) begin
                        item.payload[i] = captured_payload[i];
                    end

                    `uvm_info("MON", $sformatf("Captured TLP frame: length=%0d bytes", item.payload.size()), UVM_HIGH)
                    mon_ap.write(item);
                end
            end
        end
    endtask

endclass

`endif