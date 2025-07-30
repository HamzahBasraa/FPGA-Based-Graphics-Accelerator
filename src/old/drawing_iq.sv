//Verilog HDL for "COMP32211", "drawing_iq" "functional"


`timescale 1ns / 10ps 
module drawing_iq (input  wire        clk,
		   input  wire        cmd_iq_req,
		   output reg         cmd_iq_ack,
		   input  wire        cmd_iq_rnw,
		   output reg         cmd_iq_busy,
                   input  wire [19:0] cmd_iq_address,
                   input  wire  [7:0] cmd_iq_w_data,
		   output reg   [7:0] cmd_iq_r_data,
		   output wire [31:0] iq_w_data,
		   input  wire [31:0] iq_r_data,
		   output reg  [17:0] iq_address,
		   output reg   [3:0] iq_nbyte,
		   output reg         iq_rnw,
		   output reg         iq_req,
		   input  wire        iq_ack);

reg [7:0] w_data;
reg       ack_L;

initial cmd_iq_busy = 0;
initial iq_req = 0;

always @ (posedge clk)
begin
ack_L <= iq_ack;			// Delayed version of ack pulse
					// indicates timing of -data- transfer
if (cmd_iq_req && !cmd_iq_busy)		// Incoming and not already busy
  begin
  iq_rnw <= cmd_iq_rnw;			// Capture parameters
  iq_address <= cmd_iq_address[19:2];	// Word address
  case (cmd_iq_address[1:0])		// Decode byte select
    2'b00: iq_nbyte <= 4'b1110;
    2'b01: iq_nbyte <= 4'b1101;
    2'b10: iq_nbyte <= 4'b1011;
    2'b11: iq_nbyte <= 4'b0111;
  endcase
  if (!cmd_iq_rnw) w_data <= cmd_iq_w_data;
  cmd_iq_ack <= 1;			// We've started so
  iq_req <= 1;				//  request framestore
  cmd_iq_busy <= 1;			//  and flag up as busy
  end
else
  begin
  cmd_iq_ack <= 0;			// Only high for 1 cycle
  if (iq_ack) iq_req <= 0;		// Remove request on iq_ack
  if (ack_L)				// Latch data one cycle later
    begin
    if (cmd_iq_rnw)
      case (cmd_iq_address[1:0])	// If reading, multiplex chosen byte
        2'b00: cmd_iq_r_data <= iq_r_data[7:0];
        2'b01: cmd_iq_r_data <= iq_r_data[15:8];
        2'b10: cmd_iq_r_data <= iq_r_data[23:16];
        2'b11: cmd_iq_r_data <= iq_r_data[31:24];
      endcase
    cmd_iq_busy <= 0;			// Also go idle again
    end
  end
end
  
assign iq_w_data = {4{w_data}};		// Replicate 8-bit data across bus

endmodule
