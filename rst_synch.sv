module rst_synch (
  input logic clk, RST_n,
  output logic rst_n
);

logic ff1;

always_ff @(negedge clk, negedge RST_n)
  if (!RST_n) ff1 <= 0;
  else ff1 <= 1;

always_ff @(negedge clk, negedge RST_n)
  if (!RST_n) rst_n <= 0;
  else rst_n <= ff1;

endmodule