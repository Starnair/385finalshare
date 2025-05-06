module control (
    input  logic clk,
    input  logic reset_s,
    input  logic play_s,
    input  logic switch_s,
    input  logic [15:0] SW,
    output logic stop_audio,
    output logic raw_en,
    output logic high_en,
    output logic low_en,
    output logic avg_en,
    output logic echo_en,
    output logic notch_en
);

    // FSM state
    typedef enum logic [0:0] {
        IDLE,
        PLAYING
    } state_t;

    state_t state, state_next;

    // Play toggle
    logic play_s_prev, play_edge;
    always_ff @(posedge clk) play_s_prev <= play_s;
    assign play_edge = play_s && !play_s_prev;

    always_ff @(posedge clk) begin
        if (reset_s)
            state <= IDLE;
        else
            state <= state_next;
    end

    always_comb begin
        state_next = state;
        case (state)
            IDLE:    if (play_edge) state_next = PLAYING;
            PLAYING: if (play_edge) state_next = IDLE;
        endcase
    end

    // Filter apply (BTN[2])
    logic switch_s_prev, switch_edge;
    always_ff @(posedge clk) switch_s_prev <= switch_s;
    assign switch_edge = switch_s && !switch_s_prev;

    typedef enum logic [2:0] {
        FILTER_RAW   = 3'd0,
        FILTER_HIGH  = 3'd1,
        FILTER_LOW   = 3'd2,
        FILTER_AVG   = 3'd3,
        FILTER_ECHO  = 3'd4,
        FILTER_NOTCH = 3'd5
    } filter_t;

    filter_t selected_filter;

    always_ff @(posedge clk) begin
        if (reset_s)
            selected_filter <= FILTER_RAW;
        else if (switch_edge) begin
            if      (SW[0]) selected_filter <= FILTER_HIGH;
            else if (SW[1]) selected_filter <= FILTER_LOW;
            else if (SW[2]) selected_filter <= FILTER_AVG;
            else if (SW[3]) selected_filter <= FILTER_ECHO;
            else if (SW[4]) selected_filter <= FILTER_NOTCH;
            else            selected_filter <= FILTER_RAW;
        end
    end

    // Output logic
    always_comb begin
        stop_audio = (state == IDLE);

        // Default to 0
        raw_en   = 1'b0;
        high_en  = 1'b0;
        low_en   = 1'b0;
        avg_en   = 1'b0;
        echo_en  = 1'b0;
        notch_en = 1'b0;

        if (state == PLAYING) begin
            case (selected_filter)
                FILTER_RAW:   raw_en   = 1'b1;
                FILTER_HIGH:  high_en  = 1'b1;
                FILTER_LOW:   low_en   = 1'b1;
                FILTER_AVG:   avg_en   = 1'b1;
                FILTER_ECHO:  echo_en  = 1'b1;
                FILTER_NOTCH: notch_en = 1'b1;
                default:      raw_en   = 1'b1;
            endcase
        end
    end

endmodule
