`timescale 1ns/1ps

module MedianFilter_TB;

	parameter WIDTH = 430;
	parameter HEIGHT = 554;
	parameter [7:0] BORDER_WHITE_HIGH = 8'd245;
	parameter [7:0] BORDER_WHITE_DIFF = 8'd20;

	reg clk;
	reg rst_n;
	reg start;
	wire done;

	MedianFilter #(
		.WIDTH(WIDTH),
		.HEIGHT(HEIGHT),
		.BORDER_WHITE_HIGH(BORDER_WHITE_HIGH),
		.BORDER_WHITE_DIFF(BORDER_WHITE_DIFF)
	) dut (
		.clk(clk),
		.rst_n(rst_n),
		.start(start),
		.done(done)
	);

	always #1 clk = ~clk;

	initial begin
		clk = 1'b0;
		rst_n = 1'b0;
		start = 1'b0;

		#5;
		rst_n = 1'b1;
		$display("[TB] Reset released");

		#4;
		start = 1'b1;
		$display("[TB] Start asserted");

		#2;
		start = 1'b0;

		wait (done == 1'b1);
		$display("[TB] DONE: MedianFilter IP finished full-image scan");

		#5;
		$finish;
	end

	initial begin
		#20000000;
		$display("[TB] ERROR: timeout waiting for done");
		$finish;
	end

endmodule
