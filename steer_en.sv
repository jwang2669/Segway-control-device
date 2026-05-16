module steer_en #(parameter fast_sim = 1) (
  input logic clk, rst_n,
  input logic [11:0] lft_ld, rght_ld,
  output logic en_steer, rider_off
);

// 1.34s Timer /////////
logic clr_tmr, tmr_full;
logic [25:0] timer;

generate
  if (fast_sim)
    always_ff @(posedge clk, negedge rst_n)
      if (!rst_n) timer <= 0;
      else timer <= clr_tmr ? 0 : (&timer[14:0] ? timer : timer + 1);
  else
    always_ff @(posedge clk, negedge rst_n)
      if (!rst_n) timer <= 0;
      else timer <= clr_tmr ? 0 : (timer == 26'd67000000 ? timer : timer + 1);
endgenerate

generate
  if (fast_sim)
    assign tmr_full = &timer[14:0];
  else
    assign tmr_full = timer == 26'd67000000;
endgenerate

// steer_en_SM ///////////////////////////////////////////
localparam MIN_RIDER_WT = 13'h200, WT_HYSTERESIS = 13'h40;
logic diff_gt_15_16, diff_gt_1_4, sum_gt_min, sum_lt_min;
logic [11:0] abs_diff;
logic [12:0] sum;

assign abs_diff = lft_ld >= rght_ld ? lft_ld - rght_ld : rght_ld - lft_ld;
assign sum = lft_ld + rght_ld;
assign diff_gt_15_16 = abs_diff > 17'(sum) * 4'd15 >> 4;
assign diff_gt_1_4 = abs_diff > sum >> 2;
assign sum_gt_min = sum > MIN_RIDER_WT + WT_HYSTERESIS;
assign sum_lt_min = sum < MIN_RIDER_WT - WT_HYSTERESIS;

steer_en_SM STEER_EN_SM (
  .clk(clk), .rst_n(rst_n),
  .diff_gt_1_4(diff_gt_1_4), .diff_gt_15_16(diff_gt_15_16), .sum_gt_min(sum_gt_min), .sum_lt_min(sum_lt_min), .tmr_full(tmr_full),
  .clr_tmr(clr_tmr), .en_steer(en_steer), .rider_off(rider_off)
);

endmodule