/******************************************************************************/
/*                                                                            */
/*  Module:   template                                                        */
/*  Modified: August 2025                                                     */
/*  Author:   J Garside                                                       */
/*                                                                            */
/*  Description:                                                              */
/*  This is an inactive cell which takes the place of a drawing function.     */
/*  It 'ties off' outputs tidily.                                             */
/*                                                                            */
/******************************************************************************/
 
`timescale 1ns / 10ps 

module template( input  logic        clk,             /* CHANGE MODULE NAME!  */
                 input  logic        reset,
                 input  logic        req,             /* Interface to command */
                 output logic        ack,

                 input  logic [31:0] r0,              /*  General arguments   */
                 input  logic [31:0] r1,
                 input  logic [31:0] r2,
                 input  logic [31:0] r3,
                 input  logic [31:0] r4,
                 input  logic [31:0] r5,
                 input  logic [31:0] r6,
                 input  logic [31:0] r7,
                 output logic        busy,            /*    Status outputs    */
                 output logic        done,

                 output logic        de_req,          /* Framestore interface */
                 input  logic        de_ack,
                 output logic [17:0] de_addr,
                 output logic  [3:0] de_nbyte,
                 output logic        de_rnw,
                 output logic [31:0] de_w_data,
                 input  logic [31:0] de_r_data,

                 input  logic [17:0] display_base,    /* Display status info. */
                 input  logic  [1:0] display_mode,    /*  *May* be used for   */
                 input  logic  [9:0] display_height,  /*  added flexibility.  */
                 input  logic  [9:0] display_width );


localparam TPD = 2;                      /* Define a "local parameter"        */

always_ff @ (posedge clk)                /* Respond to (spurious?) request    */
  if (req && !ack) ack <= #TPD 1'b1;     /* Signals ('inertially') delayed    */
  else             ack <= #TPD 1'b0;     /*  to make action more obvious.     */

assign busy      =  1'b0;                /* Never busy                        */
assign done      =  ack;                 /* Dummy unit is 'done' immediately; */
                                         /*      (Not the general case!)      */
assign de_req    =  1'b0;                /* Never outputs pixels              */
assign de_addr   = 18'hxxxxx;            /* Output buses not defined          */
assign de_nbyte  =  4'b1111;             /* No enables either                 */
assign de_rnw    =  1'b1;                /* Read 'safer' than write           */
assign de_w_data = 32'hxxxx_xxxx;        /* Output buses not defined          */

endmodule
