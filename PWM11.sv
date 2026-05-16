module PWM11 (
  input logic clk, rst_n,
  input logic [10:0] duty,
  output logic ovr_I_blank, PWM1, PWM2, PWM_synch
);

// 11 Bit Counter //
logic [10:0] cnt;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) cnt <= 0;
  else cnt <= cnt + 1;

///////////////////////////////
localparam NONOVERLAP = 11'h40;

assign ovr_I_blank = (NONOVERLAP < cnt && cnt < 12'(NONOVERLAP) + 11'd128) | (12'(duty) + NONOVERLAP < cnt && cnt < 12'(duty) + NONOVERLAP + 11'd128);

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) PWM1 <= 0;
  else PWM1 <= cnt >= duty ? 0 : (cnt >= NONOVERLAP ? 1 : PWM1);

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) PWM2 <= 0;
  else PWM2 <= &cnt ? 0 : (cnt >= 12'(duty) + NONOVERLAP ? 1 : PWM2);

assign PWM_synch = ~|cnt;

endmodule