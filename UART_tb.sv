module UART_tb();

logic clk, rst_n, trmt;
logic [7:0] tx_data;
logic tx_done, TX;
UART_tx uartTx (.clk(clk), .rst_n(rst_n), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done), .TX(TX));

logic clr_rdy;
logic [7:0] rx_data;
logic rdy;
UART_rx uartRx (.clk(clk), .rst_n(rst_n), .RX(TX), .clr_rdy(clr_rdy), .rx_data(rx_data), .rdy(rdy));

initial clk = 0;
always #10 clk = ~clk;

initial begin
  clr_rdy = 0;
  #200; // initialize state machine outputs at first posedge clk
  rst_n = 0;
  rst_n = 1;
  trmt = 0;

  // Load data and trigger transmission
  tx_data = 8'hA5; // 10100101
  trmt = 1;
  #50; // wait for next posedge clk to load into flip flop
  trmt = 0;

  wait (rdy === 1);
  if (rx_data == 8'hA5) $display("good1"); // when rdy is asserted, rx_data should hold the original input byte
  else $display("bad1");
  if (tx_done == 0) $display("good2"); // tx_done is half a period slower than rdy
  else $display("bad2");

  wait (tx_done === 1);
  if (tx_done == 1) $display("good3");
  else $display("bad3");

  clr_rdy = 1;
  #21;
  if (rdy === 0) $display("good4"); // clr_rdy should clear rdy
  else $display("bad4");
  clr_rdy = 0;

  $stop;
end

endmodule