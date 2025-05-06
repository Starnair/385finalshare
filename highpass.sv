module high_pass_filter (
    input  logic             clk,
    input  logic             rst,
    input  logic             high_en,
    input  logic signed [7:0] x_in,      // current PCM input
    output logic signed [7:0] y_out      // filtered output
);

    // Internal state
    logic signed [15:0] x_prev;          // previous input (extended for calc)
    logic signed [15:0] y_prev;          // previous output
    logic signed [15:0] diff, scaled;
    logic signed [15:0] result;
    logic signed [15:0] y_temp;

    // Filter coefficient in Q1.7 format (alpha ? 0.96 �� 123)
    localparam signed [7:0] ALPHA_Q1_7 = 8'd123;

    always_ff @(posedge clk) begin
        if (rst) begin
            x_prev <= 16'sd0;
            y_prev <= 16'sd0;
            y_out  <= 8'sd0;
        end else if (high_en) begin
            // Compute difference: x[n] - x[n-1]
            diff = $signed(x_in) - x_prev;

            // Compute scaled previous output: alpha * y[n-1]
            scaled = (ALPHA_Q1_7 * y_prev) >>> 7;

            // Calculate current output: y[n] = diff + alpha * y[n-1]
            y_temp = diff + scaled;

            // Update internal state for next cycle
            x_prev <= $signed(x_in);
            y_prev <= y_temp;

            // Saturate and output result as 8-bit signed value
            if (y_temp > 127)
                y_out <= 8'sd127;
            else if (y_temp < -128)
                y_out <= -8'sd128;
            else
                y_out <= y_temp[7:0];
        end
        // else: retain previous state
    end

endmodule
