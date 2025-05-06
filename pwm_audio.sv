module pwm_audio_stereo (
    input  logic         clk_in,      // 100 MHz system clock
    input  logic         rst_in,      // Active-high reset
    input  logic         tick_in,     // Tick signal (e.g., 48 kHz)
    input  logic signed [7:0] sample_l_in, // Signed 8-bit left audio sample
    input  logic signed [7:0] sample_r_in, // Signed 8-bit right audio sample
    output logic         pwm_out_l,   // Left PWM output
    output logic         pwm_out_r    // Right PWM output
);

    // Internally store offset-binary (unsigned) version of input
    logic [7:0] level_l;
    logic [7:0] level_r;
    
    assign level_l = {~sample_l_in[7], sample_l_in[6:0]}; // Flip MSB
    assign level_r = {~sample_r_in[7], sample_r_in[6:0]}; // Flip MSB

    logic [7:0] count; // Shared counter for both channels

    // PWM output logic
    assign pwm_out_l = (count < level_l);
    assign pwm_out_r = (count < level_r);

    // PWM Counter Update
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            count <= 8'b0;
        end
        else begin
            count <= count + 8'b1;
        end
    end

endmodule
