// ============================================================================
// Class: pcie_driver
// Description: Unpacks high-level sequence items and drives cycle-accurate
//              TLP transactions across the virtual interface to the DUT.
// ============================================================================

`ifndef PCIE_DRIVER_SV
`define PCIE_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class pcie_driver extends uvm_driver #(pcie_seq_item);
    `uvm_component_utils(pcie_driver)

    virtual pcie_if vif;

    function new(string name = "pcie_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual pcie_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRV_CFG_ERR", "Virtual interface not found in uvm_config_db!")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Reset bus state
        vif.drv_cb.tlp_tx_valid <= 1'b0;
        vif.drv_cb.tlp_tx_sop   <= 1'b0;
        vif.drv_cb.tlp_tx_eop   <= 1'b0;
        vif.drv_cb.tlp_tx_data  <= 8'h00;
        vif.drv_cb.ext_ack_valid<= 1'b0;
        vif.drv_cb.ext_nak_valid<= 1'b0;
        vif.drv_cb.ext_dllp_seq <= 12'd0;

        @(posedge vif.rst_n);
        @(vif.drv_cb);

        forever begin
            seq_item_port.get_next_item(req);
            drive_tlp(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_tlp(pcie_seq_item item);
        int pkt_size;
        pkt_size = item.payload.size();

        `uvm_info("DRV", $sformatf("Driving TLP: size=%0d bytes, corrupt_crc=%0b", 
                  pkt_size, item.corrupt_crc), UVM_HIGH)

        for (int i = 0; i < pkt_size; i++) begin
            // Wait until the DUT indicates it can accept data
            while (!vif.drv_cb.tlp_tx_ready) begin
                @(vif.drv_cb);
            end

            vif.drv_cb.tlp_tx_valid <= 1'b1;
            vif.drv_cb.tlp_tx_data  <= item.payload[i];
            vif.drv_cb.tlp_tx_sop   <= (i == 0);
            vif.drv_cb.tlp_tx_eop   <= (i == pkt_size - 1);

            @(vif.drv_cb);
        end

        // De-assert control signals after transmission completes
        vif.drv_cb.tlp_tx_valid <= 1'b0;
        vif.drv_cb.tlp_tx_sop   <= 1'b0;
        vif.drv_cb.tlp_tx_eop   <= 1'b0;
        vif.drv_cb.tlp_tx_data  <= 8'h00;

        // Introduce random inter-packet gap cycles
        repeat ($urandom_range(1, 3)) @(vif.drv_cb);
    endtask

endclass

`endif