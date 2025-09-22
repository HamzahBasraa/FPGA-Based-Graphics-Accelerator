/*****************************************************************************/
/*                                                                            */
/*  Module:        drawing_clear                                              */
/*                                                                            */
/*  Description:   Screen clear to colour as passed in R0 using notional      */
/*                 VDUC input arguments.                                      */
/*                                                                            */
/*  Authors:       J.D. Garside                                               */
/*  Updated:       August 2025                                                */
/*                                                                            */
/******************************************************************************/

`timescale 1ns / 10ps 

`include "video_definitions.sv"

module drawing_clear(
    input  logic        clk,
    input  logic        reset,
    input  logic        req,
    output logic        ack,
    output logic        busy,
    output logic        done,

    input  logic [17:0] display_base,
    input  logic  [1:0] display_mode,
    input  logic  [9:0] display_width,
    input  logic  [9:0] display_height,

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
    output logic  [3:0] de_nbyte,
    output logic        de_rnw,
    output logic [31:0] de_w_data,
    input  logic [31:0] de_r_data);

typedef enum logic {IDLE, BUSY} draw_state_e;

draw_state_e draw_state;

logic [15:0] colour;                        /* Colour to be used for clearing */
logic        pixel_16;                               /* Set for 16-bit pixels */
logic [19:0] screen_size_p;                  /* In pixels: allow for overflow */
logic [19:0] screen_size;

always_comb pixel_16      = display_mode[0];
always_comb screen_size_p = display_height * display_width;
always_comb screen_size   = screen_size_p >> (2 - pixel_16);

always_ff @ (posedge clk)
begin : FSM
if (reset)
  begin
  draw_state <= IDLE;
  ack        <= 1'b0;
  colour     <= 16'h0000;
  de_addr    <= display_base;                                 /* Word address */
  end
else
  begin
  case (draw_state)
    IDLE: if (req)
            begin
            ack        <= 1'b1;
            colour     <= pixel_16 ? r0[15:0] : {2{r0[7:0]}};
            de_addr    <= display_base;                       /* Word address */
            draw_state <= BUSY;
            end
          else
            ack <= 1'b0;                  /* Not strictly needed but cautious */

    BUSY: begin
          ack <= 1'b0;
          if (de_ack)
            if (de_addr >= screen_size - 1)
              draw_state <= IDLE;
            else
              de_addr <= de_addr + 18'h00001;
          end
  endcase
  end
end

always_ff @ (posedge clk)
  done <= (draw_state == BUSY) && de_ack && (de_addr >= screen_size - 1);

assign de_req    = (draw_state == BUSY);   /* Just keep requesting until done */
assign de_rnw    = 1'b0;                                      /* Only writing */
assign de_nbyte  = (draw_state == BUSY) ? 4'b0000 : 4'b1111;
assign de_w_data = {2{colour}};
assign busy      = (draw_state == BUSY) || ((draw_state == IDLE) && req);

endmodule

/******************************************************************************/
