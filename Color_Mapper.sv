module color_mapper (
    input  logic [9:0] DrawX, DrawY,
    input  logic signed [7:0] song_sample,
    output logic [3:0] Red, Green, Blue
);
    // Internal signals
    logic waveform_on, centerline_on, grid_on;
    logic [9:0] center_y, clamped_sample_y;
    logic signed [10:0] sample_y;  // Sample Y position
    logic signed [10:0] extended_sample;  // Extended signed value

    // Constants
    assign center_y = 240;

    logic signed [10:0] shifted_sample;
    assign shifted_sample = $signed(song_sample) <<< 1;
    assign sample_y = center_y - shifted_sample;

    always_comb begin
        waveform_on = 1'b0;
        centerline_on = 1'b0;
        grid_on = 1'b0;

        // Clamp sample_y to [0, 479]
        if (sample_y > 479)
            clamped_sample_y = 479;
        else if (sample_y < 0)
            clamped_sample_y = 0;
        else
            clamped_sample_y = sample_y;

        // Draw vertical waveform line from center_y to clamped_sample_y
        if ((DrawY >= center_y && DrawY <= clamped_sample_y) ||
            (DrawY <= center_y && DrawY >= clamped_sample_y))
            waveform_on = 1'b1;

        // Draw center horizontal line
        if (DrawY == center_y)
            centerline_on = 1'b1;

        // Draw grid lines every 80x60 pixels
        if ((DrawX % 80 == 0) || (DrawY % 60 == 0))
            grid_on = 1'b1;
    end

    // Output color logic
    always_comb begin
        if (waveform_on) begin
            Red   = 4'h0;
            Green = 4'hf;
            Blue  = 4'h0;
        end else if (centerline_on) begin
            Red   = 4'h8;
            Green = 4'h8;
            Blue  = 4'h8;
        end else if (grid_on) begin
            Red   = 4'h4;
            Green = 4'h4;
            Blue  = 4'h4;
        end else begin
            Red   = 4'h0;
            Green = 4'h0;
            Blue  = 4'h0;
        end
    end
endmodule
