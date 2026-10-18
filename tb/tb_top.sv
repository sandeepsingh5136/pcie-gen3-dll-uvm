// ============================================================================
// Module: tb_top
// Description: Top-level testbench wrapper. Generates clock/reset, instantiates
//              physical interface and DUT, and kicks off UVM phases.
// ============================================================================

`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

// Include all UVM testbench classes
`include "pcie_seq_item.sv"
`include "pcie_sequence.sv"
`include "pcie_sequencer.sv"
`include "pcie_driver.sv"
`include "pcie_monitor.sv"
`include "pcie_agent.sv"
`include "pcie_scoreboard.sv"
`include "pcie_env.sv"
`include "pcie_test.sv"

module tb_top;

    logic clk;
    logic rst_n;

    // 100 MHz Clock Generation (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Asynchronous Reset Generation
    initial begin
        rst_n = 0;
        #25 rst_n = 1;
    end

    // Physical Interface
    pcie_if vif (
        .clk  (clk),
        .rst_n(rst_n)
    );

    // Hardware Design Under Test (DUT)
    pcie_dll_top #(
        .BUFFER_DEPTH(8),
        .MAX_PKT_BYTES(64)
    ) dut (
        .clk             (clk),
        .rst_n           (rst_n),

        // Upstream TX Interface
        .tlp_tx_valid    (vif.tlp_tx_valid),
        .tlp_tx_data     (vif.tlp_tx_data),
        .tlp_tx_sop      (vif.tlp_tx_sop),
        .tlp_tx_eop      (vif.tlp_tx_eop),
        .tlp_tx_ready    (vif.tlp_tx_ready),

        // Upstream RX Interface
        .tlp_rx_valid    (vif.tlp_rx_valid),
        .tlp_rx_data     (vif.tlp_rx_data),
        .tlp_rx_sop      (vif.tlp_rx_sop),
        .tlp_rx_eop      (vif.tlp_rx_eop),

        // Downstream PHY TX Interface
        .phy_tx_valid    (vif.phy_tx_valid),
        .phy_tx_data     (vif.phy_tx_data),
        .phy_tx_sop      (vif.phy_tx_sop),
        .phy_tx_eop      (vif.phy_tx_eop),

        // Downstream PHY RX Interface
        .phy_rx_valid    (vif.phy_rx_valid),
        .phy_rx_data     (vif.phy_rx_data),
        .phy_rx_sop      (vif.phy_rx_sop),
        .phy_rx_eop      (vif.phy_rx_eop),

        // DLLP Feedback
        .ext_ack_valid   (vif.ext_ack_valid),
        .ext_nak_valid   (vif.ext_nak_valid),
        .ext_dllp_seq    (vif.ext_dllp_seq),
        .local_ack_valid (vif.local_ack_valid),
        .local_nak_valid (vif.local_nak_valid),
        .local_resp_seq  (vif.local_resp_seq)
    );

    // Register interface to UVM configuration database and start test
    initial begin
        uvm_config_db#(virtual pcie_if)::set(null, "*", "vif", vif);
        run_test("pcie_test");
    end

    // Waveform dump for GTKWave
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

endmodule