`timescale 1ns / 1ps


/** 
            Top Level module for the drawing engine  

*/
module drawing(input  wire        clk,
               input  wire        reset,
               input  wire        cs_i,
               input  wire        read_i,
               input  wire        write_i,
               input  wire [31:0] address_i,
               input  wire  [1:0] size_i,
               input  wire  [1:0] mode_i,
               output wire        stall_o,
               output wire  [2:0] abort_v_o,
               input  wire [31:0] data_in,
               output reg  [31:0] data_out,
               output wire  [1:0] ireq_o,
               
               input  wire  [9:0] v_width_i,
               input  wire  [9:0] v_height_i,
               input  wire  [1:0] v_mode_i,
               input  wire [17:0] v_frame_i,

               output wire        de_req_o,  /* Bus fron drawing accelerator to FS mux. */
               output wire        de_RnW_o,
               output wire  [3:0] de_nbyte_o,
               input  wire        de_ack_i,
               output wire [17:0] de_address_o,
               output wire [31:0] de_wr_data_o,
               input  wire [31:0] de_rd_data_i);

//assign de_req_o     = 1'b0;       /* Bus fron drawing accelerator to FS mux. */
assign de_RnW_o     = 1'b0;
assign de_nbyte_o   = 4'b1001;
//assign de_address_o = 18'h00000;
assign de_wr_data_o = 32'hFFFF_0000;

assign stall_o   = 0;
assign abort_v_o = 0;
assign ireq_o    = 0;

reg [7:0] state;
reg [17:0] addr; 

reg [31:0] arg[0:7];
reg [31:0] x1, y1;
reg [31:0] x2, y2;

always @ (posedge clk)                                     /* Register writes */
if (reset)
  begin
  x1 <= 32'h0000_0000;
  y1 <= 32'h0000_0000;
  x2 <= 32'h0000_0000;
  y2 <= 32'h0000_0000;
  end
else
  if (cs_i && write_i)
    if (address_i[5] == 1'b1) arg[address_i[4:2]] <= data_in;
    else
      case (address_i[4:2])
        3'h0: x1 <= data_in;
        3'h1: y1 <= data_in;
        3'h2: x2 <= data_in;
        3'h3: y2 <= data_in;
     endcase

always @ (posedge clk)
if (reset) state <= 8'h00;
else
if (cs_i && write_i && (address_i[5:2] == 4'h7))
  state <= 8'hFF;
else if (addr == 18'h100) state <= 8'h00;

assign de_req_o     = state != 0;
assign de_address_o = addr;

always @ (posedge clk)
if (reset) addr <= 18'h00000;
else
if (state != 0)
  if (de_ack_i)
    addr <= addr + 1;
    

always @ (posedge clk)                                      /* Register reads */
if (cs_i && read_i)
  if (address_i[5] == 1'b1) data_out <= arg[address_i[4:2]];
  else
    case (address_i[4:2])
      3'h0:    data_out <= x1;
      3'h1:    data_out <= y1;
      3'h2:    data_out <= x2;
      3'h3:    data_out <= y2;
      3'h4:    data_out <= {22'h0, v_width_i};
      3'h5:    data_out <= {22'h0, v_height_i};
      3'h6:    data_out <= {30'h0, v_mode_i};
      3'h7:    data_out <= {4{state}}; 
      default: data_out <= 32'hxxxx_xxxx;
    endcase
else data_out <= 32'hxxxx_xxxx;

endmodule

/*============================================================================*/
