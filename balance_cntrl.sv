module balance_cntrl #(parameter fast_sim = 1) (
  input logic clk, rst_n,
  input logic en_steer, pwr_up, rider_off, vld,
  input logic [11:0] steer_pot,
  input logic signed [15:0] ptch, ptch_rt,
  output logic too_fast,
  output logic signed [11:0] lft_spd, rght_spd
);

logic [7:0] ss_tmr;
logic signed [11:0] PID_cntrl;

generate
  if (fast_sim)
    PID #(.fast_sim(1)) PID (
      .clk(clk), .rst_n(rst_n),
      .pwr_up(pwr_up), .rider_off(rider_off), .vld(vld), .ptch(ptch), .ptch_rt(ptch_rt),
      .ss_tmr(ss_tmr), .PID_cntrl(PID_cntrl)
    );
  else
    PID #(.fast_sim(0)) PID (
      .clk(clk), .rst_n(rst_n),
      .pwr_up(pwr_up), .rider_off(rider_off), .vld(vld), .ptch(ptch), .ptch_rt(ptch_rt),
      .ss_tmr(ss_tmr), .PID_cntrl(PID_cntrl)
    );
endgenerate

SegwayMath SEGWAYMATH (
  .en_steer(en_steer), .pwr_up(pwr_up), .ss_tmr(ss_tmr), .steer_pot(steer_pot), .PID_cntrl(PID_cntrl),
  .too_fast(too_fast), .lft_spd(lft_spd), .rght_spd(rght_spd)
);

endmodule