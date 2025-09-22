/** 
    Module:        drawing_mux_8
    
    Description:   Multiplexer for the drawing accelerator.
                   This module takes requests from up to 8 drawing units
                   and multiplexes them onto a single bus interface.
                   It also handles the acknowledgments from the selected unit.


    Authors:       James Garside & Anthony Mathews
    Date:          July 2025

*/
`define TPD 2

`timescale 1ns / 10ps 
module drawing_mux_8(   input  wire        clk,
		    input  wire        req0,
		    output wire        ack0,
		    input  wire        rnw0,
		    input  wire [17:0] addr0,
		    input  wire  [3:0] nbyte0,
		    input  wire [31:0] data0,
		    output wire [31:0] rd_data0,
		    input  wire        req1,
		    output wire        ack1,
		    input  wire        rnw1,
		    input  wire [17:0] addr1,
		    input  wire  [3:0] nbyte1,
		    input  wire [31:0] data1,
		    output wire [31:0] rd_data1,
		    input  wire        req2,
		    output wire        ack2,
		    input  wire        rnw2,
		    input  wire [17:0] addr2,
		    input  wire  [3:0] nbyte2,
		    input  wire [31:0] data2,
		    output wire [31:0] rd_data2,
		    input  wire        req3,
		    output wire        ack3,
		    input  wire        rnw3,
		    input  wire [17:0] addr3,
		    input  wire  [3:0] nbyte3,
		    input  wire [31:0] data3,
		    output wire [31:0] rd_data3,
		    input  wire        req4,
		    output wire        ack4,
		    input  wire        rnw4,
		    input  wire [17:0] addr4,
		    input  wire  [3:0] nbyte4,
		    input  wire [31:0] data4,
		    output wire [31:0] rd_data4,
		    input  wire        req5,
		    output wire        ack5,
		    input  wire        rnw5,
		    input  wire [17:0] addr5,
		    input  wire  [3:0] nbyte5,
		    input  wire [31:0] data5,
		    output wire [31:0] rd_data5,
		    input  wire        req6,
		    output wire        ack6,
		    input  wire        rnw6,
		    input  wire [17:0] addr6,
		    input  wire  [3:0] nbyte6,
		    input  wire [31:0] data6,
		    output wire [31:0] rd_data6,
		    input  wire        req7,
		    output wire        ack7,
		    input  wire        rnw7,
		    input  wire [17:0] addr7,
		    input  wire  [3:0] nbyte7,
		    input  wire [31:0] data7,
		    output wire [31:0] rd_data7,
		    output wire        de_req,
		    input  wire        de_ack,
		    output wire        de_rnw,
		    output wire [17:0] de_addr,
		    output wire  [3:0] de_nbyte,
		    output wire [31:0] de_data,
		    input  wire [31:0] de_rd_data);

reg  [2:0] pending_req;                              /* Encoded input request */
reg        hold;                    /* The output request needs to be latched */
reg        held;          /* The output request is latched waiting for de_ack */
reg  [2:0] held_req;                                   /* Staticised requests */
reg  [2:0] current_req;           /* Output request: immediate if not latched */
reg  [7:0] current_ack;

reg        mux_rnw;
reg [17:0] mux_addr;
reg  [3:0] mux_nbyte;
reg [31:0] mux_data;

assign de_req = req7 | req6 | req5 | req4 | req3 | req2 | req1 | req0;
assign ack7 = current_ack[7];
assign ack6 = current_ack[6];
assign ack5 = current_ack[5];
assign ack4 = current_ack[4];
assign ack3 = current_ack[3];
assign ack2 = current_ack[2];
assign ack1 = current_ack[1];
assign ack0 = current_ack[0];
assign de_rnw   = mux_rnw;
assign de_addr  = mux_addr;	/* Delay here because of apparent     */
assign de_nbyte = mux_nbyte;	/* Cadence simulation bug if delay in */
assign de_data  = mux_data;	/* original assignment.               */

assign rd_data0 = de_rd_data;
assign rd_data1 = de_rd_data;
assign rd_data2 = de_rd_data;
assign rd_data3 = de_rd_data;
assign rd_data4 = de_rd_data;
assign rd_data5 = de_rd_data;
assign rd_data6 = de_rd_data;
assign rd_data7 = de_rd_data;

always @ (req7, req6, req5, req4, req3, req2, req1, req0)
casex ({req7, req6, req5, req4, req3, req2, req1, req0})
  8'bxxxx_xxx1: pending_req = 0;
  8'bxxxx_xx10: pending_req = 1;
  8'bxxxx_x100: pending_req = 2;
  8'bxxxx_1000: pending_req = 3;
  8'bxxx1_0000: pending_req = 4;
  8'bxx10_0000: pending_req = 5;
  8'bx100_0000: pending_req = 6;
  8'b1000_0000: pending_req = 7;
  default:      pending_req = 0;
endcase


/* N.B. If incoming requests are not mutually exclusive then multiplexers may */
/* glitch as forward path has no latches.  Not fixable in isolation due to    */
/* input race between requests and de_ack.  Outputs must be set up in time    */
/* to be latched into memory driver.                                          */

always @ (pending_req, addr0, nbyte0, data0, rnw0, addr1, nbyte1, data1, rnw1,
                       addr2, nbyte2, data2, rnw2, addr3, nbyte3, data3, rnw3,
                       addr4, nbyte4, data4, rnw4, addr5, nbyte5, data5, rnw5,
                       addr6, nbyte6, data6, rnw6, addr7, nbyte7, data7, rnw7)
case (pending_req)
  0: begin			// Highest priority channel
     mux_rnw   = rnw0;
     mux_addr  = addr0;
     mux_nbyte = nbyte0;
     mux_data  = data0;
     end
  1: begin
     mux_rnw   = rnw1;
     mux_addr  = addr1;
     mux_nbyte = nbyte1;
     mux_data  = data1;
     end
  2: begin
     mux_rnw   = rnw2;
     mux_addr  = addr2;
     mux_nbyte = nbyte2;
     mux_data  = data2;
     end
  3: begin
     mux_rnw   = rnw3;
     mux_addr  = addr3;
     mux_nbyte = nbyte3;
     mux_data  = data3;
     end
  4: begin
     mux_rnw   = rnw4;
     mux_addr  = addr4;
     mux_nbyte = nbyte4;
     mux_data  = data4;
     end
  5: begin
     mux_rnw   = rnw5;
     mux_addr  = addr5;
     mux_nbyte = nbyte5;
     mux_data  = data5;
     end
  6: begin
     mux_rnw   = rnw6;
     mux_addr  = addr6;
     mux_nbyte = nbyte6;
     mux_data  = data6;
     end
  7: begin
     mux_rnw   = rnw7;
     mux_addr  = addr7;
     mux_nbyte = nbyte7;
     mux_data  = data7;
     end
  default: begin
     mux_rnw   = 1'b0;
     mux_addr  = 18'hxxxxx;
     mux_nbyte = 4'hf;
     mux_data  = 32'hxxxxxxxx;
     end
endcase

assign hold = de_req && !de_ack;                              /* Output stall */
always @ (posedge clk) held <= hold;                /* Output requests frozen */

always @ (posedge clk) if (hold) held_req <= current_req;
                           /* Hold requests to direct ack correctly as needed */
assign current_req = held ? held_req : pending_req;         /* Hold or bypass */

always @ (de_ack, current_req)
case (current_req)
  0: current_ack = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, de_ack};
  1: current_ack = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, de_ack, 1'b0};
  2: current_ack = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, de_ack, 1'b0, 1'b0};
  3: current_ack = {1'b0, 1'b0, 1'b0, 1'b0, de_ack, 1'b0, 1'b0, 1'b0};
  4: current_ack = {1'b0, 1'b0, 1'b0, de_ack, 1'b0, 1'b0, 1'b0, 1'b0};
  5: current_ack = {1'b0, 1'b0, de_ack, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
  6: current_ack = {1'b0, de_ack, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
  7: current_ack = {de_ack, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
  default: current_ack = 8'b00000000;
endcase

endmodule
