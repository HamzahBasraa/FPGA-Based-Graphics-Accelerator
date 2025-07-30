/**
    Module:        drawing_demux_8
    
    Description:   Demultiplexer for the drawing accelerator.
                   This module takes a request from the drawing control
                   and demuxes it to one of 8 drawing units. The command
                   is also passed through to the selected unit.
                   The ack signal is ORed together from all units.

    Authors:       James Garside
    Updated:       July 2025
*/
`timescale 1ns / 10ps 
module drawing_demux_8( input  wire       de_req,
                        input  wire [2:0] de_cmd,
                        output wire       de_req0,
                        output wire       de_req1,
                        output wire       de_req2,
                        output wire       de_req3,
                        output wire       de_req4,
                        output wire       de_req5,
                        output wire       de_req6,
                        output wire       de_req7,
                        input  wire       de_ack0,
                        input  wire       de_ack1,
                        input  wire       de_ack2,
                        input  wire       de_ack3,
                        input  wire       de_ack4,
                        input  wire       de_ack5,
                        input  wire       de_ack6,
                        input  wire       de_ack7,
                        output wire       de_ack);

reg [7:0] req;

always @ (de_req, de_cmd)
begin
req = 8'b0000_0000;	// Example of using blocking assignments
req[de_cmd] = de_req;	//  to overwrite a 'default' value
end

assign de_req0 = req[0];
assign de_req1 = req[1];
assign de_req2 = req[2];
assign de_req3 = req[3];
assign de_req4 = req[4];
assign de_req5 = req[5];
assign de_req6 = req[6];
assign de_req7 = req[7];

assign de_ack = de_ack7 ||  de_ack6 ||  de_ack5 ||  de_ack4
                   || de_ack3 ||  de_ack2 ||  de_ack1 ||  de_ack0;

endmodule
