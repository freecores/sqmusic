module sq_pg(
	input clk,
	input reset_n,
	input [10:0] fnumber,
	input [2:0] block,
  input [3:0] multiple,
	output [9:0]phase );

reg [19:0] count;
assign phase = count[19:10];

wire [19:0]fmult;

always @(*) begin
  case( multiple )
    4'b0: fmult = (phase << block) >> 1'b1;
    default: fmult = (phase<<block)*multiple;
  endcase
end

always @(posedge clk or negedge reset_n ) begin
	if( !reset_n )
		count <= 20'b0;
	else begin
	  count <= count + fmult;
	end
end

endmodule

module sq_sin(
//  input clk,
//  input reset_n,
  input [9:0]phase,
  output [19:0] val
)

reg [19:0] sin_table[1023:0];

initial begin
  $readmemh("sin_table.hex", sin_table);
end

assign val = sin_table[phase];

end
