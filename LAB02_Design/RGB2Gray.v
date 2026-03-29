`timescale 1ns/1ps

module RGB2Gray #(
    parameter WIDTH = 2048,
    parameter HEIGHT = 1365,
    parameter integer BRIGHTNESS_OFFSET = 0
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

    reg [23:0] in_mem [0:N_PIX-1];
    reg [7:0] out_mem [0:N_PIX-1];

    integer idx;
    integer wr_idx;
    integer in_file;
    integer out_file;

    function [7:0] rgb_to_gray;
        input [23:0] rgb_pix;
        reg [7:0] r;
        reg [7:0] g;
        reg [7:0] b;
        reg [15:0] weighted_sum;
        reg [8:0] gray_base;
        integer gray_tmp;
    begin
        r = rgb_pix[23:16];
        g = rgb_pix[15:8];
        b = rgb_pix[7:0];

        // Integer approximation of 0.299*R + 0.587*G + 0.114*B.
        weighted_sum = (r * 8'd77) + (g * 8'd150) + (b * 8'd29);
        gray_base = weighted_sum[15:8];

        gray_tmp = gray_base + BRIGHTNESS_OFFSET;
        if (gray_tmp < 0) begin
            rgb_to_gray = 8'd0;
        end else if (gray_tmp > 255) begin
            rgb_to_gray = 8'd255;
        end else begin
            rgb_to_gray = gray_tmp[7:0];
        end
    end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            done <= 1'b0;
            idx <= 0;
            wr_idx <= 0;
            in_file <= 0;
            out_file <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        $display("[IP2] START RGB2Gray full-image scan");
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    in_file = $fopen("pic_input.txt", "r");
                    if (in_file != 0) begin
                        $fclose(in_file);
                        $readmemh("pic_input.txt", in_mem);
                        $display("[IP2] Loaded pic_input.txt");
                    end else begin
                        in_file = $fopen("../pic_input.txt", "r");
                        if (in_file != 0) begin
                            $fclose(in_file);
                            $readmemh("../pic_input.txt", in_mem);
                            $display("[IP2] Loaded ../pic_input.txt");
                        end else begin
                            $display("[IP2] ERROR: cannot find pic_input.txt");
                            $finish;
                        end
                    end

                    idx <= 0;
                    state <= S_PROCESS;
                end

                S_PROCESS: begin
                    out_mem[idx] <= rgb_to_gray(in_mem[idx]);
                    state <= S_ADVANCE;
                end

                S_ADVANCE: begin
                    if (idx == N_PIX - 1) begin
                        wr_idx <= 0;
                        state <= S_OPEN_OUT;
                    end else begin
                        idx <= idx + 1;
                        state <= S_PROCESS;
                    end
                end

                S_OPEN_OUT: begin
                    out_file = $fopen("pic_output.txt", "w");
                    if (out_file == 0) begin
                        $display("[IP2] ERROR: cannot open pic_output.txt for writing");
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
                    $display("[IP2] DONE: wrote pic_output.txt, pixels=%0d", N_PIX);
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
