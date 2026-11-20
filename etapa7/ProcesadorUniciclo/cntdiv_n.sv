module cntdiv_n #(TOPVALUE = 50_000_000) (clk, rst, clkout);
	input logic clk, rst;
	output logic clkout;
	
	// counter register 
	localparam BITS = $clog2(TOPVALUE/2);
	logic [BITS - 1 : 0] rCounter;

	// increment or reset the counter
	always @(posedge clk, posedge rst) begin
		if (rst) begin
			rCounter <= 0;
			clkout <= 0;
		end else begin
			rCounter <= rCounter + 1'b1;
			if (rCounter == TOPVALUE/2-1) begin
				clkout <= ~clkout;
				rCounter <= 0;
			end	
		end	
	end		
endmodule
