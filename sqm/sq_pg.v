/*
	SQmusic

  (c) Jose Tejada Gomez, 9th May 2013
  You can use this file following the GNU GENERAL PUBLIC LICENSE version 3
  Read the details of the license in:
  http://www.gnu.org/licenses/gpl.txt
  
  Send comments to: jose.tejada@ieee.org

*/

`timescale 1ns/1ps

module sq_slot(
	input  clk,
	input  reset_n,
	input  [10:0] fnumber,
	input  [2:0]  block,
  input  [3:0]  multiple,
  output [12:0] linear
);
	
wire [9:0]phase;
wire [12:0] sin_log, sin_linear;

sq_pg pg( 
  .clk     (clk), 
  .reset_n (reset_n), 
  .fnumber (fnumber), 
  .block   (block),
  .multiple(multiple),
  .phase   (phase) );

sq_sin sin(
  .clk     (clk), 
  .reset_n (reset_n), 
  .phase   (phase),
  .val     (sin_log) );
  
sq_pow pow(
  .clk     (clk), 
  .reset_n (reset_n), 
  .x       (sin_log),
  .y       (linear) );

endmodule

module sq_pg(
	input clk,
	input reset_n,
	input [10:0] fnumber,
	input [2:0] block,
  input [3:0] multiple,
	output [9:0]phase );

reg [19:0] count;
assign phase = count[19:10];

wire [19:0]fmult = fnumber << block;

always @(posedge clk or negedge reset_n ) begin
	if( !reset_n )
		count <= 20'b0;
	else begin
	  count <= count + ( multiple==4'b0 ? fmult>> 1 : fmult*multiple);
	end
end

endmodule

///////////////////////////////////////////////////////////////////
module sq_sin(
  input clk,
  input reset_n,
  input [9:0]phase,
  output [12:0] val // LSB is the sign. 0=positive, 1=negative
);

reg [12:0] sin_table[1023:0];

initial begin
  $readmemh("../tables/sin_table.hex", sin_table);
end
reg [9:0]last_phase;
assign val = sin_table[last_phase];

always @(posedge clk or negedge reset_n ) begin
	if( !reset_n )
		last_phase <= 10'b0;
	else begin
	  last_phase <= phase;
	end
end
endmodule
///////////////////////////////////////////////////////////////////
// sq_pow => reverse the log2 conversion
module sq_pow(
  input clk,
  input reset_n,
  input rd_n, // read enable, active low
  input [12:0]x, // LSB is the sign. 0=positive, 1=negative
  output reg [12:0]y 
);

parameter st_input    = 3'b000;
parameter st_lut_read = 3'b001;
parameter st_shift    = 3'b010;
parameter st_sign     = 3'b011;
parameter st_output   = 3'b100;

reg [2:0] state;
reg [12:0] pow_table[255:0];

initial begin
  $readmemh("../tables/pow_table.hex", pow_table);
end
reg [7:0]index;
reg [3:0]exp;
reg sign;

reg [12:0] raw, shifted, final;

always @(posedge clk or negedge reset_n ) begin
	if( !reset_n ) begin
		index <= 8'b0;
		exp   <= 3'b0;
		sign  <= 1'b0;
		raw   <= 13'b0;
		shifted <= 13'b0;
		y     <= 12'b0;
		state <= st_input;
	end
	else begin
	  case ( state )
	    st_input: begin
	      if( !rd_n ) begin
	        exp   <= x[12:9];
	        index <= x[8:1];
	        sign  <= x[0];
	        state <= st_lut_read;
	      end
	      else state <= st_lut_read;
	      end
	   st_lut_read: begin
	      raw   <= pow_table[index];
	      state <= st_shift;
	      end
	   st_shift: begin
	      shifted <= raw >> exp;
	      state   <= st_sign;
	      end
	   st_sign: begin
	      final <= sign ? ~shifted + 1'b1 : shifted;
	      state <= st_output;
	      end
	   st_output: begin
	      y     <= final;
	      state <= st_input;
	      end
	  endcase
	end
end

always @(posedge clk or negedge reset_n ) begin
	if( !reset_n ) 
	  raw <= 13'b0;
	else 
	  raw <= pow_table[index];
end

always @(posedge clk or negedge reset_n ) begin
	if( !reset_n ) 
	  shifted <= 13'b0;
	else 
	  shifted <= raw >> exp;
end

endmodule
