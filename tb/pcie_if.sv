// ============================================================================
// Interface: pcie_if
// Description: Physical & Transaction Layer interface wires, clocking blocks,
//              and protocol assertions.
// ============================================================================

interface pcie_if (input logic clk, input logic rst_n);

    // TX Transaction Layer Interface
    logic        tlp_tx_valid;
    logic [7:0]  tlp_tx_data;
    logic        tlp_tx_sop;
    logic        tlp_tx_eop;
    logic        tlp_tx_ready;

    // RX Transaction Layer Interface
    logic        tlp_rx_valid;
    logic [7:0]  tlp_rx_data;
    logic        tlp_rx_sop;
    logic        tlp_rx_eop;

    // PHY Layer Bus Signals
    logic        phy_tx_valid;
    logic [7:0]  phy_tx_data;
    logic        phy_tx_sop;
    logic        phy_tx_eop;

    logic        phy_rx_valid;
    logic [7:0]  phy_rx_data;
    logic        phy_rx_sop;
    logic        phy_rx_eop;

    // DLLP Feedback Signals
    logic        ext_ack_valid;
    logic        ext_nak_valid;
    logic [11:0] ext_dllp_seq;
    logic        local_ack_valid;
    logic        local_nak_valid;
    logic [11:0] local_resp_seq;

    // Clocking block for driver
    clocking drv_cb @(posedge clk);
        default input #1step output #1ns;
        output tlp_tx_valid, tlp_tx_data, tlp_tx_sop, tlp_tx_eop;
        input  tlp_tx_ready;
        output phy_rx_valid, phy_rx_data, phy_rx_sop, phy_rx_eop;
        output ext_ack_valid, ext_nak_valid, ext_dllp_seq;
        input  local_ack_valid, local_nak_valid, local_resp_seq;
    endclocking

    // Clocking block for monitor
    clocking mon_cb @(posedge clk);
        default input #1step output #1ns;
        input tlp_tx_valid, tlp_tx_data, tlp_tx_sop, tlp_tx_eop, tlp_tx_ready;
        input tlp_rx_valid, tlp_rx_data, tlp_rx_sop, tlp_rx_eop;
        input phy_tx_valid, phy_tx_data, phy_tx_sop, phy_tx_eop;
        input phy_rx_valid, phy_rx_data, phy_rx_sop, phy_rx_eop;
        input local_ack_valid, local_nak_valid, local_resp_seq;
    endclocking

    // Modports
    modport DRV (clocking drv_cb, input clk, rst_n);
    modport MON (clocking mon_cb, input clk, rst_n);

endinterface