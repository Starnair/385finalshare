module avg3_filter (
    input  logic clk,
    input  logic rst,
    input  logic avg_en,
    input  logic signed [7:0] x_in,
    output logic signed [7:0] y_out
);

    logic signed [7:0] x1, x2;
    logic signed [9:0] sum;

    always_ff @(posedge clk) begin
        if (rst) begin
            x1 <= 0;
            x2 <= 0;
            y_out <= 0;
        end else if (avg_en) begin
            sum = x_in + x1 + x2;
            x2 <= x1;
            x1 <= x_in;
            y_out <= sum / 3;  // integer division
        end
    end

endmodule
