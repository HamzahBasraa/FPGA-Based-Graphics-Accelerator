//Verilog HDL for "COMP32211", "drawing_demux" "functional"

`define TPD 2		// Propagation delay for cosmetic purposes in simulation

`timescale 1ns / 10ps 
module drawing_demux( input  wire       de_req,
                      input  wire [1:0] de_cmd,
                      output wire       de_req0,
                      output wire       de_req1,
                      output wire       de_req2,
                      output wire       de_req3,
		      input  wire       de_ack0,
		      input  wire       de_ack1,
		      input  wire       de_ack2,
		      input  wire       de_ack3,
                      output wire       de_ack);

reg [3:0] req;

always @ (de_req, de_cmd)
begin
req = 4'b0000;		// Example of using blocking assignments
req[de_cmd] = de_req;	//  to overwrite a 'default' value
end

assign #`TPD de_req0 = req[0];
assign #`TPD de_req1 = req[1];
assign #`TPD de_req2 = req[2];
assign #`TPD de_req3 = req[3];

assign #`TPD de_ack = de_ack3 ||  de_ack2 ||  de_ack1 ||  de_ack0;

endmodule
