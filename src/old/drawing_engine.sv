/******************************************************************************/
/* Module:   drawing_engine                                                   */
/* Modified: September 2023                                                   */
/* Author:   J Garside                                                        */
/*                                                                            */
/* Description:                                                               */
/*                                                                            */
/* Overall drawing unit container for smaller drawing function modules.       */
/*                                                                            */
/******************************************************************************/
 
`timescale 1ns / 10ps

// Declarations done in a different (older) Verilog style
// This is for illustration - not a particular recommendation!
module drawing_engine (clk, req, ack, cmd, r0, r1, r2, r3, r4, r5, r6, r7, busy,
                       de_req, de_ack, de_rnw, de_addr, de_nbyte,
                       de_data, de_rd_data );

input          clk;				// 'Global' signal

input          req;				// Host/command interface
output         ack, busy;
input  [15:0]  cmd;
input  [15:0]  r0, r1, r2, r3, r4, r5, r6, r7;

output         de_req, de_rnw;			// Framestore interface
input          de_ack;
output [17:0]  de_addr;
output  [3:0]  de_nbyte;
output [31:0]  de_data;
input  [31:0]  de_rd_data;			// Extra bus -sometimes- wanted 
   
// Buses in the design

wire    [0:3]  req_in;
wire    [0:3]  ack_in;
wire    [0:3]  busy_in;
wire   [17:0]  addr0,    addr1,    addr2,    addr3;
wire    [3:0]  nbyte0,   nbyte1,   nbyte2,   nbyte3;
wire   [31:0]  data0,    data1,    data2,    data3;
wire   [31:0]  data_rd0,           data_rd2, data_rd3;
wire   [31:0]  unconnected;			// Unit 1 has no read data bus
wire           req0, ack0, rnw0;		// Unit control signals
wire           req1, ack1, rnw1;
wire           req2, ack2, rnw2;
wire           req3, ack3, rnw3;

wire req_idle;
 
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Current bus usage                                                          */
/* [0] - drawing_dummy                                                        */
/* [1] - drawing_line                                                         */
/* [2] - drawing_dummy                                                        */
/* [3] - drawing_clear                                                        */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
 
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Instantiation of drawing_line and drawing_clear                            */
/* drawing_line                                                               */

drawing_dummy dummy_0 ( clk, req_in[0], ack_in[0], busy_in[0],
     r0[15:0], r1[15:0], r2[15:0], r3[15:0], r4[15:0], r5[15:0],
     r6[15:0], r7[15:0], req0, ack0, addr0[17:0], nbyte0[3:0], rnw0,
     data0[31:0], data_rd0[31:0]);

drawing_line Line ( clk, req_in[1], ack_in[1], busy_in[1], r0[15:0],
     r1[15:0], r2[15:0], r3[15:0], r4[15:0], r5[15:0], r6[15:0],
     r7[15:0], req1, ack1, addr1[17:0], nbyte1[3:0], data1[31:0]);
// Look carefully: some connections are different
// This is a good reason to NOT use this style!

drawing_dummy dummy_2 ( clk, req_in[2], ack_in[2], busy_in[2],
     r0[15:0], r1[15:0], r2[15:0], r3[15:0], r4[15:0], r5[15:0],
     r6[15:0], r7[15:0], req2, ack2, addr2[17:0], nbyte2[3:0], rnw2,
     data2[31:0], data_rd2[31:0]);

drawing_clear Clear_screen ( clk, req_in[3], ack_in[3], busy_in[3],
     r0[15:0], r1[15:0], r2[15:0], r3[15:0], r4[15:0], r5[15:0],
     r6[15:0], r7[15:0], req3, ack3, addr3[17:0], nbyte3[3:0], rnw3,
     data3[31:0], data_rd3[31:0]);

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Instantiation of mux and demux                                             */

drawing_demux demux ( req_idle, cmd[1:0], req_in[0], req_in[1], req_in[2],
                    req_in[3], ack_in[0], ack_in[1], ack_in[2], ack_in[3], ack);

drawing_mux Multiplexer ( clk, req0, ack0, rnw0, addr0[17:0],
     nbyte0[3:0], data0[31:0], data_rd0[31:0], req1, ack1, rnw1,
     addr1[17:0], nbyte1[3:0], data1[31:0], unconnected[31:0], req2, ack2,
     rnw2, addr2[17:0], nbyte2[3:0], data2[31:0], data_rd2[31:0], req3,
     ack3, rnw3, addr3[17:0], nbyte3[3:0], data3[31:0], data_rd3[31:0],
     de_req, de_ack, de_rnw, de_addr[17:0], de_nbyte[3:0],
     de_data[31:0], de_rd_data[31:0]);

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Additional signals                                                         */

assign busy = |busy_in[0:3];		// Uses reduction operator ('|') for OR4

assign req_idle = req && !busy;		// Only allow new 'req' if idle

/** Tie drawing_line to only write */
assign rnw1 = 0;

endmodule

/*============================================================================*/
