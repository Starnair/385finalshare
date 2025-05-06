//-------------------------------------------------------------------------
//    mb_usb_hdmi_top.sv                                                 --
//    Zuofu Cheng                                                        --
//    2-29-24                                                            --
//                                                                       --
//                                                                       --
//    Spring 2024 Distribution                                           --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module mb_usb_hdmi_top(
    input logic Clk,
    input logic [3:0] BTN,
    
    //USB signals
    input logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,
    
    //UART
    input logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,
    
    //HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0] hdmi_tmds_data_n,
    output logic [2:0] hdmi_tmds_data_p,

    // Audio
    output logic SPKL,
    output logic SPKR,
    output logic JB4_N,
    input logic [15:0] SW
);
    
    logic [31:0] keycode0_gpio, keycode1_gpio;
    logic clk_25MHz, clk_125MHz, clk, clk_100MHz;
    logic locked;
    logic [9:0] drawX, drawY, ballxsig, ballysig, ballsizesig;

    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;


    
    
    mb_usb mb_block_i (
        .clk_100MHz(Clk),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .reset_rtl_0(~reset_s), //Block designs expect active low reset, all other modules are active high
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss)
    );
        
    // Clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_s),
        .locked(locked),
        .clk_in1(Clk)
    );
    
    // VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_s),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    

    // Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        // Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        // Reset is active LOW
        .rst(reset_s),
        // Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        // Aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        // Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );

    // Ball Module
    ball ball_instance(
        .Reset(reset_s),
        .frame_clk(vsync),                    // Figure out what this should be so that the ball will move
        .keycode(keycode0_gpio[7:0]),    // Notice: only one keycode connected to ball by default
        .BallX(ballxsig),
        .BallY(ballysig),
        .BallS(ballsizesig)
    );
    
    // Color Mapper Module   
    color_mapper color_instance(
        .DrawX(drawX),
        .DrawY(drawY),
        .song_sample(vis_sample),
        .Red(red),
        .Green(green),
        .Blue(blue)
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

    sine sine_inst (
        .clk_in(Clk),
        .rst_in(reset_s),
        .step_in(tick_48khz),
        .amp_out(amp_out)
    );

    logic signed [7:0] amp_out;

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

logic signed [7:0] waveform_buffer [0:639];
always_ff @(posedge Clk) begin
    if (reset_s)
        write_ptr <= 0;
    else if (tick_48khz) begin
        waveform_buffer[write_ptr] <= audio_sample;
        write_ptr <= (write_ptr == 639) ? 0 : write_ptr + 1;
    end
end
logic signed [7:0] vis_sample;
logic [9:0] write_ptr = 0;  
assign vis_sample = waveform_buffer[drawX];


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

logic signed [7:0] display_signal;
logic signed [7:0] listen_signal;
logic signed [7:0] select_sound;
always_ff @(posedge Clk) begin
    if (SW[15]) begin  //sine
        select_sound <= amp_out;
    end
    else begin          // song
        select_sound <= song_sample;
end
end
    high_pass_filter hp_filter_inst (
         .clk(Clk),
         .rst(reset_s),
         .high_en(high_en),
         .x_in(select_sound),  // Input from ROM
         .y_out(high_sample)   // Output to PWM
     );

    low_pass_filter lp_filter_inst (
        .clk(Clk),
        .rst(reset_s),
        .low_en(low_en),
        .x_in(select_sound),  // Input from ROM
        .y_out(low_sample)   // Output to PWM
    );

    avg3_filter avg3_filter_inst (
        .clk(Clk),
        .rst(reset_s),
        .avg_en(avg_en),
        .x_in(select_sound),  // Input from ROM
        .y_out(avg3_sample)   // Output to PWM
    );

    echo_filter echo_filter_inst (
        .clk(Clk),
        .rst(reset_s),
        .echo_en(echo_en),
        .x_in(select_sound),  // Input from ROM
        .y_out(echo_sample)   // Output to PWM
    );

    notch_filter notch_filter_inst (
        .clk(Clk),
        .rst(reset_s),
        .notch_en(notch_en),
        .x_in(select_sound),  // Input from ROM
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
        audio_sample = select_sound;
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
