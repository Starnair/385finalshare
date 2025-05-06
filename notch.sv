module notch_filter (
    input  logic clk,
    input  logic rst,
    input  logic notch_en,
    input  logic signed [7:0] x_in,
    output logic signed [7:0] y_out
);

    // Fixed-point Q1.15 format
    localparam signed [15:0] a1 = 16'sd62259;  // 2*cos(w0), Q1.15 (≈ 1.9)
    localparam signed [15:0] r  = 16'sd31785;  // r = 0.97, Q1.15
    localparam signed [15:0] r2 = 16'sd30223;  // r^2 = 0.94, Q1.15
    localparam signed [15:0] ra1 = 16'sd59641; // 2*r*cos(w0), Q1.15 (≈ 1.8)

    logic signed [15:0] x1, x2;  // x[n-1], x[n-2]
    logic signed [15:0] y1, y2;  // y[n-1], y[n-2]

    logic signed [31:0] xn_term, xn1_term, xn2_term, yn1_term, yn2_term;
    logic signed [31:0] result;

    always_ff @(posedge clk) begin
        if (rst) begin
            x1 <= 0; x2 <= 0;
            y1 <= 0; y2 <= 0;
            y_out <= 0;
        end else if (notch_en) begin
            // Convert input to Q1.15
            logic signed [15:0] x0 = {x_in, 8'b0};  // 8-bit to Q1.15

            // Apply difference equation (Q1.15 math)
            xn_term  = x0;
            xn1_term = -((a1 * x1) >>> 15);
            xn2_term = x2;
            yn1_term = (ra1 * y1) >>> 15;
            yn2_term = -((r2 * y2) >>> 15);

            result = xn_term + xn1_term + xn2_term + yn1_term + yn2_term;

            // Clip back to 8-bit signed
            if (result > 32767)
                y_out <= 8'sd127;
            else if (result < -32768)
                y_out <= -8'sd128;
            else
                y_out <= result[15:8]; // Convert back from Q1.15 to 8-bit
              
            // Update delay lines
            x2 <= x1;
            x1 <= x0;
            y2 <= y1;
            y1 <= result[15:0];
        end
    end

endmodule
