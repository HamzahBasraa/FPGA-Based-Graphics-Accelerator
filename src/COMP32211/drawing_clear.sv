/** 
    Module:        drawing_clear
    
    Description:   Holding module for the drawing systems sub units.
                   Muxes control signals, and demuxes the bus to the
                   framestore. 
                   8 drawing units can be house within this module.

    Authors:       James Garside
    Updated:       July 2025

*/
`timescale 1ns / 10ps 

`include "video_definitions.sv"

module drawing_clear(
    input  logic        clk,
    input  logic        reset,
    input  logic        req,
    output logic        ack,
    output logic        busy,

    input  logic [17:0] display_base,
    input  logic [9:0]  display_height,
    input  logic [1:0]  display_mode,
    input  logic [9:0]  display_width,

    input  logic [15:0] r0,
    input  logic [15:0] r1,
    input  logic [15:0] r2,
    input  logic [15:0] r3,
    input  logic [15:0] r4,
    input  logic [15:0] r5,
    input  logic [15:0] r6,
    input  logic [15:0] r7,
    output logic        de_req,
    input  logic        de_ack,
    output logic [17:0] de_addr,
    output logic [3:0]  de_nbyte,
    output logic        de_rnw,
    output logic [31:0] de_w_data,
    input  logic [31:0] de_r_data
);

typedef enum logic {IDLE, BUSY} draw_state_e;
draw_state_e draw_state;

logic [7:0]   colour;  // Colour to be used for clearing

// Frame size calculation (assuming X_SIZE and Y_SIZE are defined in video_definitions.sv)
localparam int WORDS_PER_FRAME = (`X_SIZE * `Y_SIZE) >> 2;

always_ff @(posedge clk) begin
    if (reset) begin
        draw_state <= IDLE;
        ack        <= 1'b0;
        colour     <= 8'h00;
        de_addr    <= 18'h0;
    end else begin
        case (draw_state)
            IDLE: begin
                if (req) begin
                    ack      <= 1'b1;
                    colour   <= r0[7:0];
                    de_addr  <= 18'h0;
                    draw_state <= BUSY;
                end else begin
                    ack <= 1'b0;
                end
            end
            BUSY: begin
                ack <= 1'b0;
                if (de_ack) begin
                    if (de_addr >= WORDS_PER_FRAME - 1) begin
                        draw_state <= IDLE;
                    end else begin
                        de_addr <= de_addr + 1;
                    end
                end
            end
        endcase
    end
end

assign de_req   = (draw_state == BUSY);
assign de_rnw   = 1'b0;
assign de_nbyte = 4'b0000;
assign de_w_data = {4{colour}};
assign busy     = (draw_state == BUSY);

endmodule