/* 
  Module:           drawing_line_plus
  Description:      This module implements a line drawing algorithm for
                    the drawing engine.

  Authors:          James Garside & Anthony Mathews
  Modified:         August 2025
*/

`timescale 1ns / 10ps

module drawing_line_plus (
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
    output logic [31:0] de_w_data);

/* State machine states for drawing line */
typedef enum logic [1:0] {IDLE, READ, WRITE} draw_state_e;
draw_state_e draw_state;

/* Internal signals for drawing line algorithm */
logic [11:0] error;
logic [9:0]  dab;
logic [9:0]  db;
logic [10:0] onestep;
logic [10:0] twostep;
logic [19:0] address;
logic [9:0]  length;
logic [7:0]  mask;
logic [7:0]  colour;
logic [7:0]  colour_out;

logic [19:0] onestep_ext;                    /* Sign extended to address size */
logic [19:0] twostep_ext;
logic [11:0] compare;
logic [19:0] address_in;

logic        col_bypass;                        /* Use input not latched data */
logic  [7:0] input_colour;                           /* Chosen pixel's colour */
logic  [7:0] old_col_L;                     /* Latched FS read in case needed */

//logic [9:0] count_read, count_write;	// Just monitoring/debug

assign address_in   = r4[19:0];
assign onestep_ext = { {9{onestep[10]}}, onestep };
assign twostep_ext = { {9{twostep[10]}}, twostep };
assign compare = error - (db << 1);

assign de_rnw    = draw_state != WRITE;
assign de_req    = busy;
assign busy      = draw_state != IDLE;
assign de_addr   = address[19:2];
assign de_w_data = {4{colour_out}};

always_ff @(posedge clk)
begin
if (reset)
  begin
  draw_state <= IDLE;
  ack        <=  1'b0;
  error      <= 12'h000;
  dab        <= 10'h000;
  db         <= 10'h000;
  onestep    <= 20'h00000;
  twostep    <= 20'h00000;
  address    <= 20'h00000;
  length     <= 10'h000;
  mask       <=  8'h00;
  colour     <=  8'h00;
  done       <=  1'b0;
  end
else
  begin
  case (draw_state)

    IDLE:
      begin
      done <= 1'b0;
      if (req)
        begin
        ack      <= 1'b1;
        error    <= r0[9:0];
        dab      <= r0[9:0] - r1[9:0];
        db       <= r1[9:0];
        onestep  <= r2[10:0];
        twostep  <= r3[10:0];
        address  <= address_in;
        length   <= r0[9:0];
        mask     <= r5[7:0];
        colour   <= r6[7:0];
        draw_state <= (r5[7:0] != 8'h00) ? READ : WRITE;      /* Read needed? */
        end
      else
        ack <= 1'b0;
      end

    READ:
      begin 
      if (de_ack)   /* Only proceed in response to completion of previous op. */
        begin
        draw_state <= WRITE;
        col_bypass <= 1'b1;                          /* FS input colour valid */
	end
      end

    WRITE:
      begin
      ack <= 1'b0;                     /* No longer idle so must have 'ack'ed */
      col_bypass <= 1'b0;                          /* FS input colour invalid */
      if (de_ack)   /* Only proceed in response to completion of previous op. */
        begin
        if (length == 0)                 /* Last output ack-ed; back to sleep */
          begin
          draw_state <= IDLE;
          done       <= 1'b1;
          end
        else
          begin
          draw_state <= (mask != 8'h00) ? READ : WRITE;       /* Read needed? */
          if (!compare[11])                       /* Effectively the sign bit */
            begin
            error   <= compare;
            address <= address + onestep_ext;
            end
          else
            begin
            error   <= error + (dab << 1);
            address <= address + twostep_ext;
            end
          length <= length - 1;            /* Count from 'N' to 0 -inclusive- */
          end
        end
      end

  endcase
  end
end

always_comb
unique
  case(address[1:0])
    2'b00 :  de_nbyte = 4'b1110;
    2'b01 :  de_nbyte = 4'b1101;
    2'b10 :  de_nbyte = 4'b1011;
    2'b11 :  de_nbyte = 4'b0111;
    default: de_nbyte = 4'b1111;
  endcase

always_ff @(posedge clk)
  if (col_bypass) old_col_L <= input_colour;

always @ (*)
if (col_bypass)                         /* Use 'raw' read data from input bus */
  case (address[1:0])                      /* Address same for read and write */
    2'b00:   input_colour = de_r_data[7:0];
    2'b01:   input_colour = de_r_data[15:8];
    2'b10:   input_colour = de_r_data[23:16];
    2'b11:   input_colour = de_r_data[31:24];
    default: input_colour = 8'hxx;
  endcase
else input_colour = old_col_L;                          /* Use retained input */

assign colour_out = (input_colour & mask) ^ colour;

/*
 always_ff @(posedge clk)	// Just monitoring/debug @@@
if (reset || (draw_state == IDLE))
  begin
  count_read  <= 0;
  count_write <= 0;
  end
else
  if (de_ack)
    if (de_rnw) count_read++;
    else        count_write++;
*/

endmodule
