// --- Module: pcie_rx_engine ---
module pcie_rx_engine (
    input  logic        clk,
    input  logic        rst_n,

    // Physical Layer (PHY) RX Interface
    input  logic        phy_rx_valid,
    input  logic [7:0]  phy_rx_data,
    input  logic        phy_rx_sop,
    input  logic        phy_rx_eop,

    // Feedback DLLP
    output logic        ack_dllp_valid,
    output logic        nak_dllp_valid,
    output logic [11:0] resp_seq_num,

    // Forwarding to Transaction Layer
    output logic        tlp_rx_valid,
    output logic [7:0]  tlp_rx_data,
    output logic        tlp_rx_sop,
    output logic        tlp_rx_eop
);

    typedef enum logic [2:0] {
        RX_IDLE,
        RX_SEQ_MSB,
        RX_SEQ_LSB,
        RX_PAYLOAD,
        RX_CRC_CHECK
    } rx_fsm_t;

    rx_fsm_t state, next_state;

    logic [11:0] expected_seq;
    logic [11:0] received_seq;

    logic [31:0] crc_reg, next_crc_val;
    logic [31:0] received_crc;
    logic [1:0]  crc_byte_cnt;
    logic [7:0]  crc_data_in;

    logic [7:0]  temp_buf [0:63];
    logic [5:0]  buf_wr_ptr, buf_rd_ptr;
    logic [5:0]  pkt_len;
    logic        forwarding_active;

    pcie_crc32 rx_crc_inst (
        .current_crc(crc_reg),
        .data_in    (crc_data_in),
        .next_crc   (next_crc_val)
    );

    always_comb begin
        case (state)
            RX_SEQ_MSB: crc_data_in = phy_rx_data;
            RX_SEQ_LSB: crc_data_in = phy_rx_data;
            RX_PAYLOAD: crc_data_in = phy_rx_data;
            default:    crc_data_in = 8'h00;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state             <= RX_IDLE;
            expected_seq      <= 12'd0;
            received_seq      <= 12'd0;
            crc_reg           <= 32'hFFFFFFFF;
            received_crc      <= 32'd0;
            crc_byte_cnt      <= 2'd0;
            buf_wr_ptr        <= 6'd0;
            buf_rd_ptr        <= 6'd0;
            pkt_len           <= 6'd0;
            forwarding_active <= 1'b0;
            ack_dllp_valid    <= 1'b0;
            nak_dllp_valid    <= 1'b0;
            resp_seq_num      <= 12'd0;
            tlp_rx_valid      <= 1'b0;
            tlp_rx_sop        <= 1'b0;
            tlp_rx_eop        <= 1'b0;
            tlp_rx_data       <= 8'h00;
        end else begin
            state          <= next_state;
            ack_dllp_valid <= 1'b0;
            nak_dllp_valid <= 1'b0;

            if (forwarding_active) begin
                tlp_rx_valid <= 1'b1;
                tlp_rx_data  <= temp_buf[buf_rd_ptr];
                tlp_rx_sop   <= (buf_rd_ptr == 6'd0);
                tlp_rx_eop   <= (buf_rd_ptr == pkt_len - 1'b1);

                buf_rd_ptr <= buf_rd_ptr + 1'b1;
                if (buf_rd_ptr == pkt_len - 1'b1) begin
                    forwarding_active <= 1'b0;
                end
            end else begin
                tlp_rx_valid <= 1'b0;
                tlp_rx_sop   <= 1'b0;
                tlp_rx_eop   <= 1'b0;
            end

            case (state)
                RX_IDLE: begin
                    crc_reg      <= 32'hFFFFFFFF;
                    crc_byte_cnt <= 2'd0;
                    buf_wr_ptr   <= 6'd0;
                    if (phy_rx_valid && phy_rx_sop) begin
                        received_seq[11:8] <= phy_rx_data[3:0];
                        crc_reg            <= next_crc_val;
                    end
                end

                RX_SEQ_LSB: begin
                    if (phy_rx_valid) begin
                        received_seq[7:0] <= phy_rx_data;
                        crc_reg           <= next_crc_val;
                    end
                end

                RX_PAYLOAD: begin
                    if (phy_rx_valid) begin
                        if (!phy_rx_eop) begin
                            temp_buf[buf_wr_ptr] <= phy_rx_data;
                            buf_wr_ptr           <= buf_wr_ptr + 1'b1;
                            crc_reg              <= next_crc_val;
                        end
                    end
                end

                RX_CRC_CHECK: begin
                    if (phy_rx_valid) begin
                        received_crc[31 - (crc_byte_cnt * 8) -: 8] <= phy_rx_data;
                        crc_byte_cnt <= crc_byte_cnt + 1'b1;

                        if (crc_byte_cnt == 2'd3) begin
                            if ((received_seq == expected_seq) && (crc_reg == {received_crc[31:8], phy_rx_data})) begin
                                ack_dllp_valid    <= 1'b1;
                                resp_seq_num      <= received_seq;
                                expected_seq      <= expected_seq + 1'b1;
                                pkt_len           <= buf_wr_ptr;
                                buf_rd_ptr        <= 6'd0;
                                forwarding_active <= 1'b1;
                            end else begin
                                nak_dllp_valid <= 1'b1;
                                resp_seq_num   <= expected_seq;
                                buf_wr_ptr     <= 6'd0;
                            end
                        end
                    end
                end
            endcase
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            RX_IDLE:       if (phy_rx_valid && phy_rx_sop) next_state = RX_SEQ_LSB;
            RX_SEQ_LSB:    if (phy_rx_valid) next_state = RX_PAYLOAD;
            RX_PAYLOAD:    if (phy_rx_valid && phy_rx_eop) next_state = RX_CRC_CHECK;
            RX_CRC_CHECK:  if (phy_rx_valid && (crc_byte_cnt == 2'd3)) next_state = RX_IDLE;
            default:       next_state = RX_IDLE;
        endcase
    end
endmodule