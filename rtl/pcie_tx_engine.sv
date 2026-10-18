// --- Module: pcie_tx_engine ---
module pcie_tx_engine #(
    parameter BUFFER_DEPTH  = 8,
    parameter MAX_PKT_BYTES = 64
)(
    input  logic        clk,
    input  logic        rst_n,

    // Interface from Transaction Layer
    input  logic        tlp_valid,
    input  logic [7:0]  tlp_data,
    input  logic        tlp_sop,
    input  logic        tlp_eop,
    output logic        tlp_ready,

    // Feedback DLLP Interface
    input  logic        ack_received,
    input  logic        nak_received,
    input  logic [11:0] dllp_seq_num,

    // Physical Layer (PHY) TX Interface
    output logic        phy_tx_valid,
    output logic [7:0]  phy_tx_data,
    output logic        phy_tx_sop,
    output logic        phy_tx_eop
);

    typedef enum logic [3:0] {
        ST_IDLE,
        ST_SEQ_MSB,
        ST_SEQ_LSB,
        ST_PAYLOAD,
        ST_CRC,
        ST_REPLAY_SEQ_MSB,
        ST_REPLAY_SEQ_LSB,
        ST_REPLAY_PAYLOAD,
        ST_REPLAY_CRC
    } tx_fsm_t;

    tx_fsm_t state, next_state;

    logic [11:0] next_tx_seq;
    logic [31:0] crc_reg, next_crc_val;
    logic [1:0]  crc_byte_cnt;
    logic [7:0]  crc_data_in;

    pcie_crc32 crc_inst (
        .current_crc(crc_reg),
        .data_in    (crc_data_in),
        .next_crc   (next_crc_val)
    );

    logic [7:0]  replay_mem [0:BUFFER_DEPTH-1][0:MAX_PKT_BYTES-1];
    logic [11:0] replay_seq [0:BUFFER_DEPTH-1];
    logic [7:0]  replay_len [0:BUFFER_DEPTH-1];

    logic [2:0]  wr_slot, rd_slot;
    logic [7:0]  byte_idx;
    logic [7:0]  replay_byte_idx;

    // Ready when IDLE or continuously streaming payload
    assign tlp_ready = (state == ST_IDLE) || (state == ST_PAYLOAD && !tlp_eop);

    always_comb begin
        case (state)
            ST_SEQ_MSB:        crc_data_in = {4'b0000, next_tx_seq[11:8]};
            ST_SEQ_LSB:        crc_data_in = next_tx_seq[7:0];
            ST_PAYLOAD:        crc_data_in = tlp_data;
            ST_REPLAY_SEQ_MSB: crc_data_in = {4'b0000, replay_seq[rd_slot][11:8]};
            ST_REPLAY_SEQ_LSB: crc_data_in = replay_seq[rd_slot][7:0];
            ST_REPLAY_PAYLOAD: crc_data_in = replay_mem[rd_slot][replay_byte_idx];
            default:           crc_data_in = 8'h00;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= ST_IDLE;
            next_tx_seq     <= 12'd0;
            wr_slot         <= 3'd0;
            rd_slot         <= 3'd0;
            byte_idx        <= 8'd0;
            replay_byte_idx <= 8'd0;
            crc_byte_cnt    <= 2'd0;
            crc_reg         <= 32'hFFFFFFFF;
            phy_tx_valid    <= 1'b0;
            phy_tx_sop      <= 1'b0;
            phy_tx_eop      <= 1'b0;
            phy_tx_data     <= 8'h00;
        end else begin
            state <= next_state;

            if (ack_received) begin
                rd_slot <= rd_slot + 1'b1;
            end

            case (state)
                ST_IDLE: begin
                    phy_tx_valid <= 1'b0;
                    phy_tx_sop   <= 1'b0;
                    phy_tx_eop   <= 1'b0;
                    crc_reg      <= 32'hFFFFFFFF;
                    crc_byte_cnt <= 2'd0;
                    byte_idx     <= 8'd0;
                end

                ST_SEQ_MSB: begin
                    phy_tx_valid <= 1'b1;
                    phy_tx_sop   <= 1'b1;
                    phy_tx_data  <= {4'b0000, next_tx_seq[11:8]};
                    crc_reg      <= next_crc_val;
                    replay_seq[wr_slot] <= next_tx_seq;
                end

                ST_SEQ_LSB: begin
                    phy_tx_sop   <= 1'b0;
                    phy_tx_data  <= next_tx_seq[7:0];
                    crc_reg      <= next_crc_val;
                end

                ST_PAYLOAD: begin
                    if (tlp_valid) begin
                        phy_tx_valid <= 1'b1;
                        phy_tx_data  <= tlp_data;
                        crc_reg      <= next_crc_val;
                        replay_mem[wr_slot][byte_idx] <= tlp_data;
                        byte_idx <= byte_idx + 1'b1;

                        if (tlp_eop) begin
                            replay_len[wr_slot] <= byte_idx + 1'b1;
                            wr_slot             <= wr_slot + 1'b1;
                            next_tx_seq         <= next_tx_seq + 1'b1;
                            crc_byte_cnt        <= 2'd0;
                        end
                    end else begin
                        phy_tx_valid <= 1'b0;
                    end
                end

                ST_CRC: begin
                    phy_tx_valid <= 1'b1;
                    phy_tx_data  <= crc_reg[31 - (crc_byte_cnt * 8) -: 8];
                    crc_byte_cnt <= crc_byte_cnt + 1'b1;
                    if (crc_byte_cnt == 2'd3) begin
                        phy_tx_eop <= 1'b1;
                    end
                end

                ST_REPLAY_SEQ_MSB: begin
                    crc_reg         <= 32'hFFFFFFFF;
                    crc_byte_cnt    <= 2'd0;
                    replay_byte_idx <= 8'd0;
                    phy_tx_valid    <= 1'b1;
                    phy_tx_sop      <= 1'b1;
                    phy_tx_data     <= {4'b0000, replay_seq[rd_slot][11:8]};
                    crc_reg         <= next_crc_val;
                end

                ST_REPLAY_SEQ_LSB: begin
                    phy_tx_sop   <= 1'b0;
                    phy_tx_data  <= replay_seq[rd_slot][7:0];
                    crc_reg      <= next_crc_val;
                end

                ST_REPLAY_PAYLOAD: begin
                    phy_tx_valid <= 1'b1;
                    phy_tx_data  <= replay_mem[rd_slot][replay_byte_idx];
                    crc_reg      <= next_crc_val;
                    replay_byte_idx <= replay_byte_idx + 1'b1;
                end

                ST_REPLAY_CRC: begin
                    phy_tx_valid <= 1'b1;
                    phy_tx_data  <= crc_reg[31 - (crc_byte_cnt * 8) -: 8];
                    crc_byte_cnt <= crc_byte_cnt + 1'b1;
                    if (crc_byte_cnt == 2'd3) begin
                        phy_tx_eop <= 1'b1;
                    end
                end
            endcase
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            ST_IDLE: begin
                if (nak_received)
                    next_state = ST_REPLAY_SEQ_MSB;
                else if (tlp_valid && tlp_sop)
                    next_state = ST_SEQ_MSB;
            end
            ST_SEQ_MSB:  next_state = ST_SEQ_LSB;
            ST_SEQ_LSB:  next_state = ST_PAYLOAD;
            ST_PAYLOAD:  if (tlp_valid && tlp_eop) next_state = ST_CRC;
            ST_CRC:      if (crc_byte_cnt == 2'd3) next_state = ST_IDLE;
            ST_REPLAY_SEQ_MSB: next_state = ST_REPLAY_SEQ_LSB;
            ST_REPLAY_SEQ_LSB: next_state = ST_REPLAY_PAYLOAD;
            ST_REPLAY_PAYLOAD: begin
                if (replay_byte_idx == replay_len[rd_slot] - 1)
                    next_state = ST_REPLAY_CRC;
            end
            ST_REPLAY_CRC: if (crc_byte_cnt == 2'd3) next_state = ST_IDLE;
            default: next_state = ST_IDLE;
        endcase
    end
endmodule