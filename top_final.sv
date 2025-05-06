// BRAM-based circular buffer for audio samples using sdcard_init
module audio_pwm_top (
    input  logic CLK_100MHZ,
    input  logic [3:0] BTN,
    input  logic [15:0] SW,
    output logic SPKL,
    output logic SPKR,
    output logic JB4_N
);


	logic [23:0] tone_counter;
    logic [15:0] play_addr;
    logic signed [7:0] song_sample;
    logic [15:0] song_length = 16'd192000; // e.g., 1 second song at 48kHz (update if needed)
    logic ram_we;
    logic get_sd;
    logic ram_op_begun;
    logic ram_init_error;
    logic ram_init_done;
    logic reset_s;
    logic play_s;
    logic switch_s;
    logic stop_audio;
    logic raw_en;
    logic high_en;
    logic low_en;
    logic avg_en;
    logic echo_en;
    logic notch_en;
    logic signed [7:0] audio_sample;
    logic signed [7:0] high_sample;
    logic signed [7:0] low_sample;
    logic signed [7:0] avg3_sample;
    logic signed [7:0] echo_sample;
    logic signed [7:0] notch_sample;

    assign JB4_N = SPKL; // Optional secondary output

    // 48kHz tick generator
    logic [15:0] tick_counter;
    logic tick_48khz = (tick_counter == 2082);

    always_ff @(posedge Clk) begin
        if (reset_s)
            tick_counter <= 0;
        else if (tick_48khz)
            tick_counter <= 0;
        else
            tick_counter <= tick_counter + 1;
    end



    // Playback pointer
    always_ff @(posedge Clk) begin
        if (reset_s)
            play_addr <= 0;
        else if (tick_48khz && !stop_audio) begin
            if (play_addr == song_length - 1)
                play_addr <= 0;  // Auto-loop after reaching end
            else
                play_addr <= play_addr + 1;
        end
    end

    control control (
        .clk(Clk),
        .reset_s(reset_s),
        .play_s(play_s),
        .switch_s(switch_s),
        .SW(SW[15:0]),
        .stop_audio(stop_audio),
        .raw_en(raw_en),
        .high_en(high_en),
        .low_en(low_en),
        .avg_en(avg_en),
        .echo_en(echo_en),
        .notch_en(notch_en)
    );


    high_pass_filter hp_filter_inst (
         .clk(Clk),
         .rst(reset_s),
         .high_en(high_en),
         .x_in(song_sample),  // Input from ROM
         .y_out(high_sample)   // Output to PWM
     );

    low_pass_filter lp_filter_inst (
        .clk(Clk),
        .rst(reset_s),
        .low_en(low_en),
        .x_in(song_sample),  // Input from ROM
        .y_out(low_sample)   // Output to PWM
    );

    avg3_filter avg3_filter_inst (
        .clk(Clk),
        .rst(reset_s),
        .avg_en(avg_en),
        .x_in(song_sample),  // Input from ROM
        .y_out(avg3_sample)   // Output to PWM
    );

    echo_filter echo_filter_inst (
        .clk(Clk),
        .rst(reset_s),
        .echo_en(echo_en),
        .x_in(song_sample),  // Input from ROM
        .y_out(echo_sample)   // Output to PWM
    );

    notch_filter notch_filter_inst (
        .clk(Clk),
        .rst(reset_s),
        .notch_en(notch_en),
        .x_in(song_sample),  // Input from ROM
        .y_out(notch_sample)   // Output to PWM
    );

    song_bram_wrapper rom_inst (
        .clk(Clk),
        .play_addr(play_addr),
        .dout(song_sample)
    );

always_comb begin
    audio_sample = 8'sd0;
    if (raw_en)
        audio_sample = song_sample;
    else if (high_en)
        audio_sample = high_sample;
    else if (low_en)
        audio_sample = low_sample;
    else if (avg_en)
        audio_sample = avg3_sample;
    else if (echo_en)
        audio_sample = echo_sample;
    else if (notch_en) 
        audio_sample = notch_sample;
end

    // PWM output
    pwm_audio_stereo pwm_inst (
        .clk_in(Clk),
        .rst_in(reset_s),
        .sample_l_in(audio_sample),
        .sample_r_in(audio_sample),
        .pwm_out_l(SPKL),
        .pwm_out_r(SPKR)
    );

	sync_debounce button_sync [2:0] (
	   .clk    (Clk),
	   
	   .d      ({BTN[0], BTN[1], BTN[2]}),
	   .q      ({reset_s, play_s, switch_s})
	);

endmodule
