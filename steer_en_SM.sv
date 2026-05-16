module steer_en_SM (
  input logic clk, rst_n,
  input logic diff_gt_15_16, diff_gt_1_4, sum_gt_min, sum_lt_min, tmr_full,
  output logic clr_tmr, en_steer, rider_off
);

// State Machine //////////////////////////////////////////
typedef enum logic [1:0] {INITIAL, BALANCE, STEER} state_t;
state_t state, next_state;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) state <= INITIAL;
  else state <= next_state;

always_comb begin
  next_state = INITIAL;
  clr_tmr = 0; en_steer = 0; rider_off = 0;
  case (state)
    INITIAL:
      if (sum_gt_min) begin
        next_state = BALANCE;
        clr_tmr = 1; en_steer = 0; rider_off = 0;
      end else begin
        next_state = INITIAL;
        clr_tmr = 1; en_steer = 0; rider_off = 1;
      end
    BALANCE:
      if (sum_lt_min) begin
        next_state = INITIAL;
        clr_tmr = 1; en_steer = 0; rider_off = 1;
      end else if (diff_gt_1_4) begin
        next_state = BALANCE;
        clr_tmr = 1; en_steer = 0; rider_off = 0;
      end else if (!diff_gt_1_4 && !tmr_full) begin
        next_state = BALANCE;
        clr_tmr = 0; en_steer = 0; rider_off = 0;
      end else if (!diff_gt_1_4 && tmr_full) begin
        next_state = STEER;
        clr_tmr = 1; en_steer = 1; rider_off = 0;
      end
    STEER:
      if (sum_lt_min) begin
        next_state = INITIAL;
        clr_tmr = 1; en_steer = 0; rider_off = 1;
      end else if (diff_gt_15_16) begin
        next_state = BALANCE;
        clr_tmr = 1; en_steer = 0; rider_off = 0;
      end else begin
        next_state = STEER;
        clr_tmr = 1; en_steer = 1; rider_off = 0;
      end
    default: begin
      next_state = INITIAL;
      clr_tmr = 1; en_steer = 0; rider_off = 1;
    end
  endcase
end

endmodule