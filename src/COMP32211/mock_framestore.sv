`timescale 1ns / 1ps

/*
    Module:        drawing_clear

    Description:   This module provides a mocked framestore interface
                   for the drawing accelerator. It simulates the behaviour
                   of a framestore by providing read and write operations
                   to a simulated memory array.

    Authors:       James Garside & Anthony Mathews
    Updated:       August 2025
*/


module mock_framestore(
                 input  logic	     n_CS_i, 
                 input  logic	     n_rd_i, 
                 input  logic	     n_wr_i, 
                 input  logic [17:0] addr_i,
                 input  logic [3:0]  n_bytes_i,
                 input  logic	     n_write_i, 
                 output logic [31:0] d_load_o,
                 input  logic [31:0] d_store_i,
		 input  logic        use_vscreen);

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
reg [7:0] frame_store2 [0:131071];	//
reg [7:0] frame_store3 [0:131071];	// 
 

/******************************************************************************/
/* SRAM simulation logic / hooks 
/******************************************************************************/
 
  

/** Model Asynchronous RAM Reads */
always @ (n_CS_i, addr_i, n_rd_i, n_bytes_i) begin

    #(simulationDelay);

    if (!n_CS_i && !n_rd_i) begin

        if (~n_bytes_i[0]) d_load_o[7:0] = frame_store0[addr_i];
        else d_load_o[7:0] = 8'hx;  
        if (~n_bytes_i[1]) d_load_o[15:8] = frame_store1[addr_i];
        else d_load_o[15:8] = 8'hx; 
        if (~n_bytes_i[2]) d_load_o[24:16] = frame_store2[addr_i];
        else d_load_o[23:16] = 8'hx; 
        if (~n_bytes_i[3]) d_load_o[31:24] = frame_store3[addr_i];
        else d_load_o[31:24] = 8'hx; 
    end

end

/** Models Asynchronous RAM Writes */
always @ (n_CS_i, addr_i, n_wr_i, n_bytes_i) begin
    
    #(simulationDelay);
  
    /* Models the Asynchronous RAM used on the Lab Board, and also
       interacts with the Virtual Screen for visualization */
    if (~n_CS_i && ~n_wr_i) begin
        

        if (debug_display_debug_output && n_wr_i === 1'b0 ) begin
            $display("Framestore write: Addr: %h \t nbytes: %h data: %h", addr_i, n_bytes_i, d_store_i);
        end

        if (~n_bytes_i[0]) 
            begin 
                frame_store0[addr_i] = d_store_i[7:0]; 
                if (use_vscreen)
                  $write_screen(123, 0, addr_i, d_store_i[7:0]); 
            end
        if (~n_bytes_i[1])
            begin
                frame_store1[addr_i] = d_store_i[15:8];
                if (use_vscreen)
                  $write_screen(123, 1, addr_i, d_store_i[15:8]); 
            end
        if (~n_bytes_i[2])
            begin
                frame_store2[addr_i] = d_store_i[24:16]; 
                if (use_vscreen)
                  $write_screen(123, 2, addr_i, d_store_i[24:16]); 
            end
        if (~n_bytes_i[3])
            begin
                frame_store3[addr_i] = d_store_i[31:24];
                if (use_vscreen)
                  $write_screen(123, 3, addr_i, d_store_i[31:24]); 
            end 
    end

end


endmodule
