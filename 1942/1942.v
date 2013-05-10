/*
	1942 simple board setup in order to test SQMUSIC.
	
	Requirements:
		  TV80, Z80 Verilog module
		 	Dump of Z80 ROM from 1942 board

  (c) Jose Tejada Gomez, 9th May 2013
  You can use this file following the GNU GENERAL PUBLIC LICENSE version 3
  Read the details of the license in:
  http://www.gnu.org/licenses/gpl.txt
  
  Send comments to: jose.tejada@ieee.org

*/

`timescale 1ns / 1ps

module sound1942;
  wire [7:0]cpu_in, cpu_out;
  wire [15:0]adr;
  wire m1_n, mreq_n, iorq_n, rd_n, wr_n, rfsh_n, halt_n, busak_n;
  wire bus_error;
  // inputs to Z80
  reg reset_n, clk, wait_n, int_n, nmi_n, busrq_n, sound_clk;

  initial begin
    //$dumpfile("dump.lxt");
    //$dumpvars(1,map.ym2203_0);    
//		$dumpvars();
//    $dumpon;
//		$shm_open("1942.shm");
//		$shm_probe( sound1942, "ACTFS" );
    reset_n=0;
    nmi_n=1;
    wait_n=1;
    #1500 reset_n=1;
		// change finish time depending on song
//		#400e6 $finish;
    #10e9 $finish;
  end    
  
  always begin // main clock
    clk=0;
    forever clk = #167 ~clk;
  end

  always begin // sound clock
    sound_clk=0;
    forever sound_clk = #334 ~sound_clk;
  end

	parameter int_low_time=167*2*80;

  always begin // interrupt clock
    int_n=1;
    forever begin
			#(4166667-int_low_time) int_n=0; // 240Hz
			//$display("IRQ request @ %t us",$time/1e6);
			#(int_low_time) int_n=1;
		end
  end
			
  
  tv80n cpu( //outputs
  .m1_n(m1_n), .mreq_n(mreq_n), .iorq_n(iorq_n), .rd_n(rd_n), .wr_n(wr_n), 
  .rfsh_n(rfsh_n), .halt_n(halt_n), .busak_n(busak_n), .A(adr), .do(cpu_out), 
  // Inputs
  .reset_n(reset_n), .clk(clk), .wait_n(wait_n), 
  .int_n(int_n), .nmi_n(nmi_n), .busrq_n(busrq_n), .di(cpu_in) );
  
  MAP map( .adr(adr), .din(cpu_out), .dout(cpu_in), .clk(clk), 
		.sound_clk( sound_clk ), .wr_n(wr_n), .rd_n(rd_n), 
		.bus_error(bus_error), .reset_n(reset_n) );
  


endmodule

/////////////////////////////////////////////////////
module MAP(
  input [15:0] adr,
  input [7:0] din,
  output [7:0] dout,  
  input clk,
	input sound_clk,
  input rd_n,
  input wr_n,
	input reset_n,
  output bus_error );
	
	wire [3:0] ay0_a, ay0_b, ay0_c, ay1_a, ay1_b, ay1_c;
	wire [15:0] amp0_y, amp1_y;

  wire [7:0]ram_out, rom_out, latch_out;
  wire rom_enable = adr<16'h4000 ? 1:0;
  wire ram_enable = adr>=16'h4000 && adr<16'h4800 ? 1:0;
  wire latch_enable = adr==16'h6000 ? 1 : 0;
  wire ay_0_enable = adr==16'h8000 || adr==16'h8001 ? 1:0;
  wire ay_1_enable = adr==16'hC000 || adr==16'hC001 ? 1:0;  
  assign bus_error = ~ram_enable & ~rom_enable & ~latch_enable &
    ~ay_0_enable & ~ay_1_enable;
  assign dout=ram_out | rom_out | latch_out;
/*
	always @(negedge rd_n)
		if( !rd_n	&& adr==8'h38 ) 
			$display("IRQ processing started @ %t us",$time/1e6);
*/   
  RAM ram(.adr(adr[10:0]), .din(din), .dout(ram_out), .enable( ram_enable ),
    .clk(clk), .wr_n(wr_n), .rd_n(rd_n) );
  ROM rom(.adr(adr[13:0]), .data(rom_out), .enable(rom_enable),
   .rd_n(rd_n), .clk(clk));
  SOUND_LATCH sound_latch( .dout(latch_out), .enable(latch_enable),
    .clk(clk), .rd_n(rd_n) );

//	fake_ay ay_0( .adr(adr[0]), .din(din), .clk(clk), .wr_n(~ay_0_enable|wr_n) );

	AY_3_8910_capcom ay_0( .reset_n(reset_n), .clk(clk), .sound_clk(sound_clk),
		.din(din), .adr(adr[0]), .wr_n(wr_n), .cs_n(~ay_0_enable),
		.A(ay0_a), .B(ay0_b), .C(ay0_c) );
	AY_3_8910_capcom ay_1( .reset_n(reset_n), .clk(clk), .sound_clk(sound_clk),
		.din(din), .adr(adr[0]), .wr_n(wr_n), .cs_n(~ay_1_enable),
		.A(ay1_a), .B(ay1_b), .C(ay1_c) );

	SQM_AMP amp0( .A(ay0_a), .B(ay0_b), .C(ay0_c), .Y( amp0_y ));
	SQM_AMP amp1( .A(ay1_a), .B(ay1_b), .C(ay1_c), .Y( amp1_y ));	
	
	always #22676 $display("%d", amp0_y+amp1_y ); // 44.1kHz sample
//  initial $dumpvars(0,ym2203_0);
endmodule

//////////////////////////////////////////////////////////
// this module is used to check the communication of the
// Z80 with the AY-3-8910
// only used for debugging
module fake_ay(
	input adr,
  input [7:0] din,
  input clk,
  input wr_n );
	
	reg [7:0] contents[1:0];
	wire sample = clk & ~wr_n;
	
	always @(posedge sample) begin
//		if( contents[adr] != din ) begin
		$display("%t -> %d = %d", $realtime/1e6, adr, din );
		if( !adr && din>15 ) $display("AY WARNING");
		contents[adr] = din;
	end
	
endmodule
	
//////////////////////////////////////////////////////////
module RAM(
  input [10:0] adr,
  input [7:0] din,
  output reg [7:0] dout,  
  input enable,
  input clk,
  input rd_n,
  input wr_n );

reg [7:0] contents[2047:0];
wire sample = clk & (~rd_n | ~wr_n );

initial dout=0;
  
always @(posedge sample) begin
  if( !enable )
    dout=0;
  else begin 
    if( !wr_n ) contents[adr]=din;
    if( !rd_n ) dout=contents[adr];
  end
end
endmodule

//////////////////////////////////////////////////////////
module ROM( 
  input  [13:0] adr, 
  output reg [7:0] data,
  input enable,
  input rd_n,
  input clk );

reg [7:0] contents[16383:0];

wire sample = clk & ~rd_n;

initial begin
  $readmemh("../rom/sr-01.c11.hex", contents ); // this is the hex dump of the ROM
  data=0;
end

always @( posedge sample ) begin
  if ( !enable )
    data=0;
  else
    data=contents[ adr ];
end
endmodule

//////////////////////////////////////////////////////////
module SOUND_LATCH(
  output reg [7:0] dout,  
  input enable,
  input clk,
  input rd_n );

wire sample = clk & ~rd_n;
reg [7:0]data;

initial begin
	dout=0;
	data=0;
	#100e6 data=8'h12; // enter the song/sound code here
end
  
always @(posedge sample) begin
  if( !enable )
		dout=0;
  else begin 
    if( !rd_n ) begin
			// $display("Audio latch read @ %t us", $realtime/1e6 );
//			if( data != 0 ) 
//			  $display("Audio latch read (%X) @ %t us", data, $realtime/1e6 );
			dout=data;
		end
  end
end
endmodule

