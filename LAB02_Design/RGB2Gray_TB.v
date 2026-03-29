`timescale 1ns/1ps

module RGB2Gray_TB;

    parameter WIDTH = 2048;
    parameter HEIGHT = 1365;
    parameter integer BRIGHTNESS_OFFSET = 0;
    reg clk;
    reg rst_n;
    reg start;
    wire done;

    RGB2Gray #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .BRIGHTNESS_OFFSET(BRIGHTNESS_OFFSET)
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
        $display("[TB2] Reset released");

        #4;
        start = 1'b1;
        $display("[TB2] Start asserted");

        #2;
        start = 1'b0;

        wait (done == 1'b1);
        $display("[TB2] DONE: RGB2Gray IP finished full-image scan");

        #5;
        $finish;
    end

    initial begin
        #30000000;
        $display("[TB2] ERROR: timeout waiting for done");
        $finish;
    end

endmodule
