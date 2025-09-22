/******************************************************************************/
/*  Module:   drawing_dummy                                                   */
/*  Modified: August 2025                                                     */
/*  Author:   J Garside                                                       */
/*                                                                            */
/*  Description:                                                              */
/*  This is an inactive cell which takes the place of a drawing function.     */
/*  It 'ties off' outputs tidily.                                             */
/******************************************************************************/
 
`timescale 1ns / 10ps 
module drawing_dummy( input  logic        clk,
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
                      output logic  [3:0] de_nbyte,
                      output logic        de_rnw,
                      output logic [31:0] de_w_data,
                      input  logic [31:0] de_r_data );

always_ff @ (posedge clk)                        /* Respond to (spurious) req */
  if (req && !ack) ack <= 1'b1;
  else             ack <= 1'b0;

assign busy      =  1'b0;
assign de_req    =  1'b0;
assign de_addr   = 18'hxxxxx;
assign de_nbyte  =  4'b1111;
assign de_rnw    =  1'b1;
assign de_w_data = 32'hxxxx_xxxx;

assign done = ack;            /* Nothing -to- do, so finished when started.   */
                              /* If 'done' is not implemented, tie to '0'     */
                              /* rather than leave a signal at the wrong time */
endmodule

/******************************************************************************/
