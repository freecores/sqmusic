/*
	SQmusic

  (c) Jose Tejada Gomez, 9th May 2013
  You can use this file following the GNU GENERAL PUBLIC LICENSE version 3
  Read the details of the license in:
  http://www.gnu.org/licenses/gpl.txt
  
  Send comments to: jose.tejada@ieee.org

*/

`timescale 1ns/1ps

module sq_opn_basic;

reg clk, reset_n;
wire signed [12:0] linear;

parameter fnumber = 11'h1;
parameter block   =  3'h0;
parameter multiple=  4'h1;

initial begin
  $dumpvars(0,sq_opn_basic);
  $dumpon;
  reset_n = 0;
  #300 reset_n=1;
  $display("SOUND START");
  #(1e10)
  $finish;
end

always begin
  clk = 0;
  forever #(125/2*144) clk = ~clk & reset_n;
end

sq_slot slot(
	.clk     (clk),
	.reset_n (reset_n),
	.fnumber (fnumber),
	.block   (block),
  .multiple(multiple),
  .linear  (linear)
);

// always #(1e9/44100) $display("%d", linear);
	

endmodule
