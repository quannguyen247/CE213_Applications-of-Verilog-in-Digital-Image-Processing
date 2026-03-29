`timescale 1ns/1ps

module MedianFilter #(
    parameter WIDTH = 430,
    parameter HEIGHT = 554,
    parameter [7:0] BORDER_WHITE_HIGH = 8'd245,
    parameter [7:0] BORDER_WHITE_DIFF = 8'd20
) (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    output reg  done
);

    localparam N_PIX = WIDTH * HEIGHT;

    localparam S_IDLE = 4'd0;
    localparam S_LOAD = 4'd1;
    localparam S_PROCESS = 4'd2;
    localparam S_ADVANCE = 4'd3;
    localparam S_OPEN_OUT = 4'd4;
    localparam S_WRITE_OUT = 4'd5;
    localparam S_CLOSE_OUT = 4'd6;
    localparam S_DONE = 4'd7;

    reg [3:0] state;

    reg [7:0] in_mem [0:N_PIX-1];
    reg [7:0] out_mem [0:N_PIX-1];

    integer x;
    integer y;
    integer idx;
    integer wr_idx;
    integer in_file;
    integer out_file;

    reg [7:0] pix_med;

    function integer clamp_coord;
        input integer value;
        input integer low_bound;
        input integer high_bound;
    begin
        if (value < low_bound) begin
            clamp_coord = low_bound;
        end else if (value > high_bound) begin
            clamp_coord = high_bound;
        end else begin
            clamp_coord = value;
        end
    end
    endfunction

    function [7:0] get_pix_clamped;
        input integer y_in;
        input integer x_in;
        integer yc;
        integer xc;
        integer addr;
    begin
        yc = clamp_coord(y_in, 0, HEIGHT - 1);
        xc = clamp_coord(x_in, 0, WIDTH - 1);
        addr = yc * WIDTH + xc;
        get_pix_clamped = in_mem[addr];
    end
    endfunction

    function [7:0] abs_diff8;
        input [7:0] a;
        input [7:0] b;
    begin
        if (a >= b) begin
            abs_diff8 = a - b;
        end else begin
            abs_diff8 = b - a;
        end
    end
    endfunction

    function [7:0] median9_19;
        input [7:0] q00, q01, q02;
        input [7:0] q10, q11, q12;
        input [7:0] q20, q21, q22;

        reg [7:0] a0, a1, a2;
        reg [7:0] b0, b1, b2;
        reg [7:0] c0, c1, c2;
        reg [7:0] low;
        reg [7:0] mid;
        reg [7:0] high;
        reg [7:0] m0, m1, m2;
    begin
        a0 = q00; a1 = q01; a2 = q02;
        if (a0 > a1) begin {a0, a1} = {a1, a0}; end
        if (a1 > a2) begin {a1, a2} = {a2, a1}; end
        if (a0 > a1) begin {a0, a1} = {a1, a0}; end

        b0 = q10; b1 = q11; b2 = q12;
        if (b0 > b1) begin {b0, b1} = {b1, b0}; end
        if (b1 > b2) begin {b1, b2} = {b2, b1}; end
        if (b0 > b1) begin {b0, b1} = {b1, b0}; end

        c0 = q20; c1 = q21; c2 = q22;
        if (c0 > c1) begin {c0, c1} = {c1, c0}; end
        if (c1 > c2) begin {c1, c2} = {c2, c1}; end
        if (c0 > c1) begin {c0, c1} = {c1, c0}; end

        low = a0;
        if (b0 > low) low = b0;
        if (c0 > low) low = c0;

        high = a2;
        if (b2 < high) high = b2;
        if (c2 < high) high = c2;

        m0 = a1; m1 = b1; m2 = c1;
        if (m0 > m1) begin {m0, m1} = {m1, m0}; end
        if (m1 > m2) begin {m1, m2} = {m2, m1}; end
        if (m0 > m1) begin {m0, m1} = {m1, m0}; end
        mid = m1;

        m0 = low; m1 = mid; m2 = high;
        if (m0 > m1) begin {m0, m1} = {m1, m0}; end
        if (m1 > m2) begin {m1, m2} = {m2, m1}; end
        if (m0 > m1) begin {m0, m1} = {m1, m0}; end

        median9_19 = m1;
    end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            done <= 1'b0;
            x <= 0;
            y <= 0;
            idx <= 0;
            wr_idx <= 0;
            in_file <= 0;
            out_file <= 0;
            pix_med <= 8'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        $display("[IP] START median filtering");
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    in_file = $fopen("pic_input.txt", "r");
                    if (in_file != 0) begin
                        $fclose(in_file);
                        $readmemh("pic_input.txt", in_mem);
                        $display("[IP] Loaded pic_input.txt");
                    end else begin
                        in_file = $fopen("../pic_input.txt", "r");
                        if (in_file != 0) begin
                            $fclose(in_file);
                            $readmemh("../pic_input.txt", in_mem);
                            $display("[IP] Loaded ../pic_input.txt");
                        end else begin
                            $display("[IP] ERROR: cannot find pic_input.txt");
                            $finish;
                        end
                    end

                    x <= 0;
                    y <= 0;
                    state <= S_PROCESS;
                end

                S_PROCESS: begin
                    idx = y * WIDTH + x;
                    pix_med = median9_19(
                        get_pix_clamped(y - 1, x - 1),
                        get_pix_clamped(y - 1, x    ),
                        get_pix_clamped(y - 1, x + 1),
                        get_pix_clamped(y    , x - 1),
                        get_pix_clamped(y    , x    ),
                        get_pix_clamped(y    , x + 1),
                        get_pix_clamped(y + 1, x - 1),
                        get_pix_clamped(y + 1, x    ),
                        get_pix_clamped(y + 1, x + 1)
                    );

                    if ((x == 0) || (x == WIDTH - 1) || (y == 0) || (y == HEIGHT - 1)) begin
                        out_mem[idx] <= in_mem[idx];
                        if ((in_mem[idx] >= BORDER_WHITE_HIGH) &&
                            (abs_diff8(in_mem[idx], pix_med) >= BORDER_WHITE_DIFF)) begin
                            out_mem[idx] <= pix_med;
                        end
                    end else begin
                        out_mem[idx] <= pix_med;
                    end

                    state <= S_ADVANCE;
                end

                S_ADVANCE: begin
                    if (x == WIDTH - 1) begin
                        x <= 0;
                        if (y == HEIGHT - 1) begin
                            wr_idx <= 0;
                            state <= S_OPEN_OUT;
                        end else begin
                            y <= y + 1;
                            state <= S_PROCESS;
                        end
                    end else begin
                        x <= x + 1;
                        state <= S_PROCESS;
                    end
                end

                S_OPEN_OUT: begin
                    out_file = $fopen("pic_output.txt", "w");
                    if (out_file == 0) begin
                        $display("[IP] ERROR: cannot open pic_output.txt for writing");
                        $finish;
                    end
                    state <= S_WRITE_OUT;
                end

                S_WRITE_OUT: begin
                    $fdisplay(out_file, "%02x", out_mem[wr_idx]);
                    if (wr_idx == N_PIX - 1) begin
                        state <= S_CLOSE_OUT;
                    end else begin
                        wr_idx <= wr_idx + 1;
                    end
                end

                S_CLOSE_OUT: begin
                    $fclose(out_file);
                    $display("[IP] DONE: wrote pic_output.txt, pixels=%0d", N_PIX);
                    done <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    if (!start) begin
                        state <= S_IDLE;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
