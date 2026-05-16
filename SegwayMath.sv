module SegwayMath (
  input logic en_steer, pwr_up,
  input logic [7:0] ss_tmr,
  input logic [11:0] steer_pot,
  input logic signed [11:0] PID_cntrl,
  output logic too_fast,
  output logic signed [11:0] lft_spd, rght_spd
);

///////////////////////////
logic signed [11:0] PID_ss;

assign PID_ss = 20'(PID_cntrl) * $signed(9'(ss_tmr)) >>> 8;

///////////////////////////////
logic [11:0] steer_pot_clipped;
logic signed [11:0] steer_control;
logic signed [12:0] lft_torque, rght_torque;

assign steer_pot_clipped = steer_pot < 12'h200 ? 12'h200 : (steer_pot > 12'hE00 ? 12'hE00 : steer_pot);
assign steer_control = 15'($signed(steer_pot_clipped - 12'h7ff)) * 3'sd3 >>> 4;
assign lft_torque = en_steer ? PID_ss + steer_control : PID_ss;
assign rght_torque = en_steer ? PID_ss - steer_control : PID_ss;

///////////////////////////////////////////////////////////////////////////////////
localparam signed GAIN_MULT = 4'sh4, LOW_TORQUE_BAND = 13'sh2A, MIN_DUTY = 13'shA8;
logic signed [12:0] lft_shaped, lft_torque_comp, rght_shaped, rght_torque_comp;

assign lft_torque_comp = lft_torque[12] ? lft_torque - MIN_DUTY : lft_torque + MIN_DUTY;
assign lft_shaped = pwr_up ? ((lft_torque[12] ? -lft_torque : lft_torque) > LOW_TORQUE_BAND ? lft_torque_comp : lft_torque * GAIN_MULT) : 0;
assign rght_torque_comp = rght_torque[12] ? rght_torque - MIN_DUTY : rght_torque + MIN_DUTY;
assign rght_shaped = pwr_up ? ((rght_torque[12] ? -rght_torque : rght_torque) > LOW_TORQUE_BAND ? rght_torque_comp : rght_torque * GAIN_MULT) : 0;

///////////////////////////////////////////////////////////////////////////
assign lft_spd = lft_shaped[12] && |(~lft_shaped[11]) ? 12'sb100000000000 :
                !lft_shaped[12] &&   |lft_shaped[11]  ? 12'sb011111111111 : $signed(lft_shaped[11:0]);
assign rght_spd = rght_shaped[12] && |(~rght_shaped[11]) ? 12'sb100000000000 :
                 !rght_shaped[12] &&   |rght_shaped[11]  ? 12'sb011111111111 : $signed(rght_shaped[11:0]);
assign too_fast = lft_spd > 12'sd1536 || rght_spd > 12'sd1536;

endmodule