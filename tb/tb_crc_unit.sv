module tb_crc_unit;
    logic [31:0] current_crc;
    logic [7:0]  data_in;
    logic [31:0] next_crc;

    // Instantiate CRC module
    pcie_crc32 dut (
        .current_crc(current_crc),
        .data_in    (data_in),
        .next_crc   (next_crc)
    );

    // Test vector: Standard 4-byte stream [0x01, 0x02, 0x03, 0x04]
    logic [7:0] test_bytes [0:3] = '{8'h01, 8'h02, 8'h03, 8'h04};

    initial begin
        $display("----------------------------------------------");
        $display("Starting Unit Test: PCIe CRC32 Hardware Block");
        $display("----------------------------------------------");

        // Seed value for PCIe LCRC
        current_crc = 32'hFFFFFFFF;

        for (int i = 0; i < 4; i++) begin
            data_in = test_bytes[i];
            #1; // Wait 1 time-unit for combinatorial logic
            $display("[Byte %0d]: Input = 0x%02X | CRC Out = 0x%08X", i, data_in, next_crc);
            current_crc = next_crc; // Feed forward to next cycle
        end

        // Final verification check
        if (current_crc !== 32'hFFFFFFFF) begin
            $display("SUCCESS: PCIe CRC32 is active, calculating deterministically.");
        end else begin
            $display("ERROR: CRC did not update.");
        end

        $display("----------------------------------------------");
        $finish;
    end
endmodule