module low_pass_filter (
    input  logic clk,
    input  logic rst,
    input  logic low_en,
    input  logic signed [7:0] x_in,
    output logic signed [7:0] y_out
);

    logic signed [15:0] y_prev;
    logic signed [15:0] scaled_in, scaled_out;

    // alpha = 0.1 → 13 in Q1.7 (0.1 * 128 ≈ 13)
    localparam signed [7:0] ALPHA = 8'd40;

    always_ff @(posedge clk) begin
        if (rst) begin
            y_prev <= 0;
            y_out  <= 0;
        end else if (low_en) begin
            scaled_in  = (ALPHA * $signed(x_in)) >>> 7;
            scaled_out = ((128 - ALPHA) * y_prev) >>> 7;
            y_prev     <= scaled_in + scaled_out;

            if ((scaled_in + scaled_out) > 127)
                y_out <= 8'sd127;
            else if ((scaled_in + scaled_out) < -128)
                y_out <= -8'sd128;
            else
                y_out <= scaled_in + scaled_out;
        end
    end

endmodule
