/** 
  Module:           drawing_line
  Description:      This module implements a line drawing algorithm for
                    the drawing engine.

  Authors:          James Garside & Anthony Mathews
  Modified:         August 2025
*/

`timescale 1ns / 10ps

module drawing_line (
    input  logic        clk,
    input  logic        reset,
    input  logic        req,
    output logic        ack,
    output logic        busy,
    output logic        done,
    input  logic [17:0] display_base,
    input  logic [9:0]  display_height,
    input  logic [1:0]  display_mode,
    input  logic [9:0]  display_width, 
    input  logic [31:0] r0,
    input  logic [31:0] r1,
    input  logic [31:0] r2,
    input  logic [31:0] r3,
    input  logic [31:0] r4,
    input  logic [31:0] r5,
    input  logic [31:0] r6,
    input  logic [31:0] r7,
    output logic        de_req,
    input  logic        de_ack,
    output logic [17:0] de_addr,
    output logic [3:0]  de_nbyte,
    output logic        de_rnw,
    input  logic [31:0] de_r_data,
    output logic [31:0] de_w_data
);

/** State machine states for drawing line */
typedef enum logic [1:0] {IDLE, BUSY, FINAL_REQ} draw_state_e;
draw_state_e draw_state;

/** Internal signals for drawing line algorithm */
logic [11:0] error;
logic [9:0]  dab;
logic [9:0]  db;
logic [10:0] onestep;
logic [10:0] twostep;
logic [19:0] address;
logic [9:0]  length;
logic [7:0]  colour;

logic [19:0] onestep_ext;
logic [19:0] twostep_ext;
logic [11:0] compare;
logic [19:0] address_in;

assign address_in   = r4[19:0];
assign onestep_ext = { {9{onestep[10]}}, onestep };
assign twostep_ext = { {9{twostep[10]}}, twostep };
assign compare = error - (db << 1);

assign de_rnw = 1'b0;   
assign de_req = busy && (length != 0);
assign busy   = (draw_state == BUSY || draw_state == FINAL_REQ);
assign de_addr = address[19:2];
assign de_w_data = {4{colour}};

always_ff @(posedge clk) begin
    if (reset) begin
        draw_state <= IDLE;
        ack        <= 1'b0;
        error      <= '0;
        dab        <= '0;
        db         <= '0;
        onestep    <= '0;
        twostep    <= '0;
        address    <= '0;
        length     <= '0;
        colour     <= '0;
        done       <= '0;
    end else begin
        case (draw_state)
            IDLE: begin
                done <= '0;
                if (req) begin
                    ack      <= 1'b1;
                    error    <= r0[9:0];
                    dab      <= r0[9:0] - r1[9:0];
                    db       <= r1[9:0];
                    onestep  <= r2[10:0];
                    twostep  <= r3[10:0];
                    address  <= address_in;
                    length   <= r0[9:0];
                    colour   <= r6[7:0];
                    draw_state <= BUSY;
                end else begin
                    ack <= 1'b0;
                end
            end
            BUSY: begin
                ack <= 1'b0;
                if (de_ack) begin
                    if (length == 0) begin
                        draw_state <= FINAL_REQ;
                    end else begin
                        if (!compare[11]) begin
                            error   <= compare;
                            address <= address + onestep_ext;
                        end else begin
                            error   <= error + (dab << 1);
                            address <= address + twostep_ext;
                        end
                        length <= length - 1;
                    end
                end else if (length == 0) begin
                    draw_state <= FINAL_REQ;
                end
            end
            FINAL_REQ : begin 
                draw_state <= IDLE; 
                done <= '1;
            end
        endcase
    end
end

always_comb begin
    unique case(address[1:0])
        2'b00 : de_nbyte = 4'b1110;
        2'b01 : de_nbyte = 4'b1101;
        2'b10 : de_nbyte = 4'b1011;
        2'b11 : de_nbyte = 4'b0111;
        default: de_nbyte = 4'b1111;
    endcase
end

endmodule
