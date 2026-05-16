module PID #(parameter fast_sim = 1) (
  input logic clk, rst_n,
  input logic pwr_up, rider_off, vld,
  input logic signed [15:0] ptch, ptch_rt,
  output logic [7:0] ss_tmr,
  output logic signed [11:0] PID_cntrl
);

// P /////////////////////////////
localparam signed P_COEFF = 5'sh9;
logic signed [9:0] ptch_err_sat;
logic signed [14:0] P_term;

assign ptch_err_sat = ptch[15] && |(~ptch[14:9]) ? 10'sb1000000000 :
                     !ptch[15] &&   |ptch[14:9]  ? 10'sb0111111111 : $signed(ptch[9:0]);
assign P_term = ptch_err_sat * P_COEFF;

// I //////////////////////
logic signed [14:0] I_term;
logic signed [17:0] I_sum, integrator, ptch_err_sat_extended;

assign ptch_err_sat_extended = ptch_err_sat;
assign I_sum = integrator + ptch_err_sat_extended;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) integrator <= 0;
  else integrator <= rider_off ? 0 : (vld & !(integrator[17] == ptch_err_sat_extended[17] && integrator[17] != I_sum[17]) ? I_sum : integrator);

generate
  if (fast_sim)
    assign I_term = integrator[17] && |(~integrator[16:15]) ? 15'sb100000000000000 :
                   !integrator[17] &&   |integrator[16:15]  ? 15'sb011111111111111 : $signed(integrator[15:1]);
  else
    assign I_term = integrator >>> 6;
endgenerate

// D //////////////////////
logic signed [12:0] D_term;

assign D_term = -(ptch_rt >>> 6);

// PID /////////////////////
logic signed [15:0] PID_sum;

assign PID_sum = P_term + I_term + D_term;
assign PID_cntrl = PID_sum[15] && |(~PID_sum[14:11]) ? 12'sb100000000000 :
                  !PID_sum[15] &&   |PID_sum[14:11]  ? 12'sb011111111111 : $signed(PID_sum[11:0]);

// Soft Start Timer //
logic [26:0] long_tmr;

generate
  if (fast_sim)
    always_ff @(posedge clk, negedge rst_n)
      if (!rst_n) long_tmr <= 0;
      else long_tmr <= pwr_up ? (&long_tmr[26:19] ? long_tmr : long_tmr + 27'd256) : 0;
  else
    always_ff @(posedge clk, negedge rst_n)
      if (!rst_n) long_tmr <= 0;
      else long_tmr <= pwr_up ? (&long_tmr[26:19] ? long_tmr : long_tmr + 1) : 0;
endgenerate

assign ss_tmr = long_tmr[26:19];

endmodule