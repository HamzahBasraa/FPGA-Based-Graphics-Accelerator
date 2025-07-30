`timescale 1ns / 1ps

/*
    Module:        drawing_clear

    Description:   This module provides a mocked framestore interface
                   for the drawing accelerator. It simulates the behavior
                   of a framestore by providing read and write operations
                   to a simulated memory array.

    Authors:       James Garside & Anthony Mathews
    Updated:       July 2025
*/


module mock_framestore(
                 input  logic         n_CS_o,        
                 input  logic         n_rd_o,                  
                 input  logic         n_wr_o,                  
                 input  logic  [17:0] addr_o,
                 input  logic   [3:0] n_bytes_o,
                 input  logic         n_write_o,        
                 output logic [31:0]  d_in_i,
                 input  reg   [31:0]  d_out_o

);

 

/* Params for controlling the mock framestore */
localparam simulationDelay = 6;
localparam debug_display_debug_output = 1;
localparam debug_clear_on_entry = 1;
localparam debug_clear_color_byte = 8'hff ;
 

integer i;
logic framestore [31231:0];

 
/* (Crude) SRAM model to represent frame store                                */
reg [7:0] frame_store0 [0:131071];	// 0.5 MB SRAM
reg [7:0] frame_store1 [0:131071];	//
reg [7:0] frame_store2 [0:131071];	//r
reg [7:0] frame_store3 [0:131071];	// 
 

/******************************************************************************/
/* SRAM simulation logic / hooks 
/******************************************************************************/
 
  

/** Model Asynchronous RAM Reads */
always @ (n_CS_o, addr_o, n_rd_o, n_bytes_o) begin

    #(simulationDelay);

    if (~n_CS_o && ~n_rd_o) begin

        if (~n_bytes_o[0]) d_in_i[7:0] = frame_store0[addr_o];
        else d_in_i[7:0] = 8'hx;  
        if (~n_bytes_o[1]) d_in_i[15:8] = frame_store1[addr_o];
        else d_in_i[15:8] = 8'hx; 
        if (~n_bytes_o[2]) d_in_i[24:16] = frame_store2[addr_o];
        else d_in_i[23:16] = 8'hx; 
        if (~n_bytes_o[3]) d_in_i[31:24] = frame_store3[addr_o];
        else d_in_i[31:24] = 8'hx; 
    end

end

/** Models Asynchronous RAM Writes */
always @ (n_CS_o, addr_o, n_wr_o, n_bytes_o) begin
    
    #(simulationDelay);
  
    /* Models the Asynchronous RAM used on the Lab Board, and also
       interacts with the Virtual Screen for visualization */
    if (~n_CS_o && ~n_wr_o) begin
        

        if (debug_display_debug_output && n_wr_o === 1'b0 ) begin
            $display("Framestore write: Addr: %h \t nbytes: %h data: %h", addr_o, n_bytes_o, d_out_o);
        end


        if (~n_bytes_o[0]) 
            begin 
                frame_store0[addr_o] = d_out_o[7:0]; 
                $write_screen(123, 0, addr_o, d_out_o[7:0]); 
            end
        if (~n_bytes_o[1])
            begin
                frame_store1[addr_o] = d_out_o[15:8];
                $write_screen(123, 1, addr_o, d_out_o[15:8]); 
            end
        if (~n_bytes_o[2])
            begin
                frame_store2[addr_o] = d_out_o[24:16]; 
                $write_screen(123, 2, addr_o, d_out_o[24:16]); 
            end
        if (~n_bytes_o[3])
            begin
                frame_store3[addr_o] = d_out_o[31:24];
                $write_screen(123, 3, addr_o, d_out_o[31:24]); 
            end 
    end

end


endmodule