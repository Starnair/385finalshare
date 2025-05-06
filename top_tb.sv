`timescale 1ns/1ps

module audio_pwm_tb;
    logic CLK_100MHZ;
    logic [3:0] BTN;
    logic SPKL, SPKR;
    logic [7:0] LED;
    logic sd_miso, sd_mosi, sd_clk, sd_cs;

    // Instantiate DUT
    audio_pwm_top dut (
        .CLK_100MHZ(CLK_100MHZ),
        .BTN(BTN),
        .SPKL(SPKL),
        .SPKR(SPKR),
        .LED(LED),
        .sd_miso(sd_miso),
        .sd_mosi(sd_mosi),
        .sd_clk(sd_clk),
        .sd_cs(sd_cs)
    );

    // 100 MHz clock generation
    always #5 CLK_100MHZ = ~CLK_100MHZ;

    // Initialize
    initial begin
        CLK_100MHZ = 0;
        BTN = 4'b0001; // Assert reset
        sd_miso = 1'b1;

        #100;
        BTN[0] = 0; // Deassert reset

        // Let simulation run for enough ticks
        #1_000_000;

    end

    // Monitor activity
    initial begin
        $dumpfile("audio_pwm_tb.vcd");
        $dumpvars(0, audio_pwm_tb);

        $display("Starting simulation...");
    end

endmodule
