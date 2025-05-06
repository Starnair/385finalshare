module echo_filter (
    input  logic clk,
    input  logic rst,
    input  logic echo_en,
    input  logic signed [7:0] x_in,
    output logic signed [7:0] y_out
);

    // Delay line (small echo)
    logic signed [7:0] delay_line [0:255];
    logic [7:0] ptr = 0;
    logic signed [15:0] mixed;

    always_ff @(posedge clk) begin
        if (rst) begin
            ptr <= 0;
            y_out <= 0;
        end else if (echo_en) begin
            mixed = x_in + (delay_line[ptr] >>> 2);  // attenuate echo

            // Saturate
            if (mixed > 127)
                y_out <= 8'sd127;
            else if (mixed < -128)
                y_out <= -8'sd128;
            else
                y_out <= mixed;

            delay_line[ptr] <= y_out;
            ptr <= ptr + 1;
        end
    end

endmodule
