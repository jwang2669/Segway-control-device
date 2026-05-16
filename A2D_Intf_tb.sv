module A2D_Intf_tb ();

logic clk, rst_n;
logic MISO, MOSI, nxt, SCLK, a2d_SS_n;
logic [11:0] batt, lft_ld, rght_ld, steer_pot;

A2D_Intf A2D_INTF (
  .clk(clk), .rst_n(rst_n), .MISO(MISO), .nxt(nxt),
  .MOSI(MOSI), .SCLK(SCLK), .SS_n(a2d_SS_n), .batt(batt), .lft_ld(lft_ld), .rght_ld(rght_ld), .steer_pot(steer_pot)
);
ADC128S ADC128S (.clk(clk), .rst_n(rst_n), .MOSI(MOSI), .SCLK(SCLK), .SS_n(a2d_SS_n), .MISO(MISO));

initial clk = 0;
always #10 clk = ~clk;

initial begin
rst_n = 0; repeat(5) @(posedge clk); rst_n = 1;

nxt = 1; repeat(2) @(posedge clk); nxt = 0;
wait(lft_ld === 12'hC00); $display("0xC00");
nxt = 1; repeat(2) @(posedge clk); nxt = 0;
wait(rght_ld === 12'hBF4); $display("0xBF4");
nxt = 1; repeat(2) @(posedge clk); nxt = 0;
wait(steer_pot === 12'hBE5); $display("0xBE5");
nxt = 1; repeat(2) @(posedge clk); nxt = 0;
wait(batt === 12'hBD6); $display("0xBD6");

nxt = 1; repeat(2) @(posedge clk); nxt = 0;
wait(lft_ld === 12'hBC0); $display("0xBC0");
nxt = 1; repeat(2) @(posedge clk); nxt = 0;
wait(rght_ld === 12'hBB4); $display("0xBB4");
nxt = 1; repeat(2) @(posedge clk); nxt = 0;
wait(steer_pot === 12'hBA5); $display("0xBA5");
nxt = 1; repeat(2) @(posedge clk); nxt = 0;
wait(batt === 12'hB96); $display("0xB96");

$stop;
end

endmodule