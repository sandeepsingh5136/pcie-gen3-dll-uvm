// ============================================================================
// DESIGN.SV: PCIe Gen 3 Data Link Layer Synthesizable RTL
// Modules: pcie_crc32, pcie_tx_engine, pcie_rx_engine, pcie_dll_top
// ============================================================================

`timescale 1ns/1ps

// --- Module: pcie_crc32 ---
module pcie_crc32 (
    input  logic [31:0] current_crc,
    input  logic [7:0]  data_in,
    output logic [31:0] next_crc
);
    logic [7:0]  d;
    logic [31:0] c;

    assign d = data_in;
    assign c = current_crc;

    always_comb begin
        next_crc[0]  = c[24] ^ c[30] ^ d[0] ^ d[6];
        next_crc[1]  = c[24] ^ c[25] ^ c[30] ^ c[31] ^ d[0] ^ d[1] ^ d[6] ^ d[7];
        next_crc[2]  = c[24] ^ c[25] ^ c[26] ^ c[30] ^ c[31] ^ d[0] ^ d[1] ^ d[2] ^ d[6] ^ d[7];
        next_crc[3]  = c[25] ^ c[26] ^ c[27] ^ c[31] ^ d[1] ^ d[2] ^ d[3] ^ d[7];
        next_crc[4]  = c[24] ^ c[26] ^ c[27] ^ c[28] ^ c[30] ^ d[0] ^ d[2] ^ d[3] ^ d[4] ^ d[6];
        next_crc[5]  = c[24] ^ c[25] ^ c[27] ^ c[28] ^ c[29] ^ c[30] ^ c[31] ^ d[0] ^ d[1] ^ d[3] ^ d[4] ^ d[5] ^ d[6] ^ d[7];
        next_crc[6]  = c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[30] ^ c[31] ^ d[1] ^ d[2] ^ d[4] ^ d[5] ^ d[6] ^ d[7];
        next_crc[7]  = c[24] ^ c[26] ^ c[27] ^ c[29] ^ c[31] ^ d[0] ^ d[2] ^ d[3] ^ d[5] ^ d[7];
        next_crc[8]  = c[24] ^ c[25] ^ c[27] ^ c[28] ^ d[0] ^ d[1] ^ d[3] ^ d[4];
        next_crc[9]  = c[25] ^ c[26] ^ c[28] ^ c[29] ^ d[1] ^ d[2] ^ d[4] ^ d[5];
        next_crc[10] = c[24] ^ c[26] ^ c[27] ^ c[29] ^ d[0] ^ d[2] ^ d[3] ^ d[5];
        next_crc[11] = c[24] ^ c[25] ^ c[27] ^ c[28] ^ d[0] ^ d[1] ^ d[3] ^ d[4];
        next_crc[12] = c[24] ^ c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[30] ^ d[0] ^ d[1] ^ d[2] ^ d[4] ^ d[5] ^ d[6];
        next_crc[13] = c[25] ^ c[26] ^ c[27] ^ c[29] ^ c[30] ^ c[31] ^ d[1] ^ d[2] ^ d[3] ^ d[5] ^ d[6] ^ d[7];
        next_crc[14] = c[26] ^ c[27] ^ c[28] ^ c[30] ^ c[31] ^ d[2] ^ d[3] ^ d[4] ^ d[6] ^ d[7];
        next_crc[15] = c[27] ^ c[28] ^ c[29] ^ c[31] ^ d[3] ^ d[4] ^ d[5] ^ d[7];
        next_crc[16] = c[24] ^ c[28] ^ c[29] ^ d[0] ^ d[4] ^ d[5];
        next_crc[17] = c[25] ^ c[29] ^ c[30] ^ d[1] ^ d[5] ^ d[6];
        next_crc[18] = c[26] ^ c[30] ^ c[31] ^ d[2] ^ d[6] ^ d[7];
        next_crc[19] = c[27] ^ c[31] ^ d[3] ^ d[7];
        next_crc[20] = c[28] ^ d[4];
        next_crc[21] = c[29] ^ d[5];
        next_crc[22] = c[24] ^ d[0];
        next_crc[23] = c[24] ^ c[25] ^ c[30] ^ d[0] ^ d[1] ^ d[6];
        next_crc[24] = c[25] ^ c[26] ^ c[31] ^ d[1] ^ d[2] ^ d[7];
        next_crc[25] = c[26] ^ c[27] ^ d[2] ^ d[3];
        next_crc[26] = c[24] ^ c[27] ^ c[28] ^ c[30] ^ d[0] ^ d[3] ^ d[4] ^ d[6];
        next_crc[27] = c[25] ^ c[28] ^ c[29] ^ c[31] ^ d[1] ^ d[4] ^ d[5] ^ d[7];
        next_crc[28] = c[26] ^ c[29] ^ c[30] ^ d[2] ^ d[5] ^ d[6];
        next_crc[29] = c[27] ^ c[30] ^ c[31] ^ d[3] ^ d[6] ^ d[7];
        next_crc[30] = c[28] ^ c[31] ^ d[4] ^ d[7];
        next_crc[31] = c[29] ^ d[5];
    end
endmodule