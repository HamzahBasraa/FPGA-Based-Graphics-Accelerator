/***********************************************************
  Module:   drawing_dummy 
  Modified: July 2023 
  Author:   J Garside 

  Description:
  This is an inactive cell which takes the place of a drawing function.
  It 'ties off' outputs tidily.
**********************************************************/ 

`define TPD 2

`timescale 1ns / 10ps 
module drawing_dummy( input  wire        clk,
                      input  wire        req,
                      output reg         ack,
                      output wire        busy,
                      input  wire [15:0] r0,
                      input  wire [15:0] r1,
                      input  wire [15:0] r2,
                      input  wire [15:0] r3,
                      input  wire [15:0] r4,
                      input  wire [15:0] r5,
                      input  wire [15:0] r6,
                      input  wire [15:0] r7,
                      output wire        de_req,
                      input  wire        de_ack,
                      output wire [17:0] de_addr,
                      output wire  [3:0] de_nbyte,
                      output wire        de_rnw,
                      output wire [31:0] de_w_data,
                      input  wire [31:0] de_r_data );

always @ (posedge clk)			// Respond to (spurious) req
  if (req && !ack) ack <= #`TPD 1;
  else             ack <= #`TPD 0;

assign busy = 0;
assign de_req = 0;
assign de_addr = 18'hxxxxx;
assign de_nbyte = 4'b1111;
assign de_rnw = 1;
assign de_w_data = 32'hxxxx_xxxx;

endmodule
