//Verilog HDL for "COMP32211", "drawing_mux" "functional"

// Modified by JSP 21-01-2019
// Combinatorial priorty block missing rnw0-3

`define TPD 2

`timescale 1ns / 10ps 
module drawing_mux( input  wire        clk,
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
		    output wire        de_req,
		    input  wire        de_ack,
		    output wire        de_rnw,
		    output wire [17:0] de_addr,
		    output wire  [3:0] de_nbyte,
		    output wire [31:0] de_data,
		    input  wire [31:0] de_rd_data);

reg  [1:0] pending_req;
reg  [1:0] current_req;
reg  [3:0] current_ack;

reg        mux_rnw;
reg [17:0] mux_addr;
reg  [3:0] mux_nbyte;
reg [31:0] mux_data;

assign #`TPD de_req = req3 | req2 | req1 | req0;
assign #`TPD ack3 = current_ack[3];
assign #`TPD ack2 = current_ack[2];
assign #`TPD ack1 = current_ack[1];
assign #`TPD ack0 = current_ack[0];
assign #`TPD de_rnw   = mux_rnw;
assign #`TPD de_addr  = mux_addr;	/* Delay here because of apparent     */
assign #`TPD de_nbyte = mux_nbyte;	/* Cadence simulation bug if delay in */
assign #`TPD de_data  = mux_data;	/* original assignment.               */

assign #`TPD rd_data0 = de_rd_data;
assign #`TPD rd_data1 = de_rd_data;
assign #`TPD rd_data2 = de_rd_data;
assign #`TPD rd_data3 = de_rd_data;

always @ (req3, req2, req1, req0)
casex ({req3, req2, req1, req0})
  4'bxxx1: pending_req = 0;
  4'bxx10: pending_req = 1;
  4'bx100: pending_req = 2;
  4'b1000: pending_req = 3;
  default: pending_req = 0;
endcase


/* N.B. If incoming requests are not mutually exclusive then multiplexers may */
/* glitch as forward path has no latches.  Not fixable in isolation due to    */
/* input race between requests and de_ack.  Outputs must be set up in time    */
/* to be latched into memory driver.                                          */

always @ (pending_req, addr0, nbyte0, data0, rnw0, addr1, nbyte1, data1, rnw1,
                       addr2, nbyte2, data2, rnw2, addr3, nbyte3, data3, rnw3)
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
endcase


always @ (posedge clk)		// Hold requests to direct ack correctly
if (!de_ack) current_req <= pending_req;

always @ (de_ack, current_req)
case (current_req)
  0: current_ack = {1'b0, 1'b0, 1'b0, de_ack};
  1: current_ack = {1'b0, 1'b0, de_ack, 1'b0};
  2: current_ack = {1'b0, de_ack, 1'b0, 1'b0};
  3: current_ack = {de_ack, 1'b0, 1'b0, 1'b0};
  default: current_ack = 4'b0000;
endcase

endmodule
