module song_bram_wrapper (
    input  logic clk,
    input  logic [15:0] play_addr,
    output logic signed [7:0] dout
);

    logic [7:0] dout_internal;

    blk_mem_gen_0 song_memory_inst (


        .clka(clk),                     //RAM->PWM
        .ena(1'b1),
        .wea(1'b0),
        .addra(play_addr),
        .dina(1'b0),
        .douta(dout_internal)
    );

    // Compensate for 2-cycle latency (optional clean-up)
    logic [7:0] dout_reg1, dout_reg2;
    always_ff @(posedge clk) begin
        dout_reg1 <= dout_internal;
        dout_reg2 <= dout_reg1;
    end

    assign dout = dout_reg2;

endmodule
