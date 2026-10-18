// --- Module: pcie_dll_top ---
module pcie_dll_top #(
    parameter BUFFER_DEPTH  = 8,
    parameter MAX_PKT_BYTES = 64
)(
    input  logic        clk,
    input  logic        rst_n,

    // Upstream Transaction Layer TX Interface
    input  logic        tlp_tx_valid,
    input  logic [7:0]  tlp_tx_data,
    input  logic        tlp_tx_sop,
    input  logic        tlp_tx_eop,
    output logic        tlp_tx_ready,

    // Upstream Transaction Layer RX Interface
    output logic        tlp_rx_valid,
    output logic [7:0]  tlp_rx_data,
    output logic        tlp_rx_sop,
    output logic        tlp_rx_eop,

    // Downstream Physical Layer (PHY) TX Bus
    output logic        phy_tx_valid,
    output logic [7:0]  phy_tx_data,
    output logic        phy_tx_sop,
    output logic        phy_tx_eop,

    // Downstream Physical Layer (PHY) RX Bus
    input  logic        phy_rx_valid,
    input  logic [7:0]  phy_rx_data,
    input  logic        phy_rx_sop,
    input  logic        phy_rx_eop,

    // DLLP Feedback
    input  logic        ext_ack_valid,
    input  logic        ext_nak_valid,
    input  logic [11:0] ext_dllp_seq,
    output logic        local_ack_valid,
    output logic        local_nak_valid,
    output logic [11:0] local_resp_seq
);

    pcie_tx_engine #(
        .BUFFER_DEPTH(BUFFER_DEPTH),
        .MAX_PKT_BYTES(MAX_PKT_BYTES)
    ) tx_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .tlp_valid    (tlp_tx_valid),
        .tlp_data     (tlp_tx_data),
        .tlp_sop      (tlp_tx_sop),
        .tlp_eop      (tlp_tx_eop),
        .tlp_ready    (tlp_tx_ready),
        .ack_received (ext_ack_valid),
        .nak_received (ext_nak_valid),
        .dllp_seq_num (ext_dllp_seq),
        .phy_tx_valid (phy_tx_valid),
        .phy_tx_data  (phy_tx_data),
        .phy_tx_sop   (phy_tx_sop),
        .phy_tx_eop   (phy_tx_eop)
    );

    pcie_rx_engine rx_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .phy_rx_valid   (phy_rx_valid),
        .phy_rx_data    (phy_rx_data),
        .phy_rx_sop     (phy_rx_sop),
        .phy_rx_eop     (phy_rx_eop),
        .ack_dllp_valid (local_ack_valid),
        .nak_dllp_valid (local_nak_valid),
        .resp_seq_num   (local_resp_seq),
        .tlp_rx_valid   (tlp_rx_valid),
        .tlp_rx_data    (tlp_rx_data),
        .tlp_rx_sop     (tlp_rx_sop),
        .tlp_rx_eop     (tlp_rx_eop)
    );

endmodule