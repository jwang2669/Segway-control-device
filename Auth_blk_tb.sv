module Auth_blk_tb ();
logic clk, rst_n;

// UART_tx
logic trmt; // assert 1 clock to initiate transmission
logic [7:0] tx_data; // byte to transmit
logic TX, tx_done; // serial data output into UART_rx, after byte done transmitting tx_done = 1 till next byte transmitted.
UART_tx UART_TX (.clk(clk), .rst_n(rst_n), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done), .TX(TX));

// Auth_blk
localparam [1:0] IDLE = 2'b00, GOT_G = 2'b01, GOT_S = 2'b10; // auth_SM states
logic rider_off, pwr_up;// Auth_blk input, Auth_blk output, pwr_up = 1 when receives G(0x47), pwr_up = 0 when last received S(0x53) and rider_off = 1
Auth_blk AUTH_BLK (.clk(clk), .rst_n(rst_n), .rider_off(rider_off), .RX(TX), .pwr_up(pwr_up));

initial clk = 0;
always #5 clk = ~clk;

initial begin
  trmt = 0; rider_off = 0;
  rst_n = 0; repeat(2) @(posedge clk); rst_n = 1; // reset the device

  tx_data = 8'h00; // send in 0, should stay in IDLE state where pwr_up = 0
  trmt = 1; repeat(2) @(posedge clk); trmt = 0;
  wait(tx_done === 1); // tx_done is asserted half a period after rx_rdy
  @(posedge clk) if (AUTH_BLK.state === IDLE && pwr_up === 0) $display("Good1"); else $display("Bad1");

  tx_data = 8'h47; // send in G, IDLE -> GOT_G where pwr_up = 1
  trmt = 1; repeat(2) @(posedge clk); trmt = 0;
  wait(tx_done === 1);
  @(posedge clk) if (AUTH_BLK.state === GOT_G && pwr_up === 1) $display("Good2"); else $display("Bad2");

  repeat(5) @(posedge clk); // GOT_G -> GOT_G where pwr_up = 1
  if (AUTH_BLK.state === GOT_G && pwr_up === 1) $display("Good3"); else $display("Bad3");

  tx_data = 8'h53; // send in S, GOT_G -> GOT_S where pwr_up = 1
  trmt = 1; repeat(2) @(posedge clk); trmt = 0;
  wait(tx_done === 1);
  @(posedge clk) if (AUTH_BLK.state === GOT_S && pwr_up === 1) $display("Good4"); else $display("Bad4");

  tx_data = 8'h00; // send in 0, GOT_S -> GOT_G where pwr_up = 1
  trmt = 1; repeat(2) @(posedge clk); trmt = 0;
  wait(tx_done === 1);
  @(posedge clk) if (AUTH_BLK.state === GOT_G && pwr_up === 1) $display("Good5"); else $display("Bad5");

  tx_data = 8'h53; // send in S, GOT_G -> GOT_S where pwr_up = 1
  trmt = 1; repeat(2) @(posedge clk); trmt = 0;
  wait(tx_done === 1);

  repeat(5) @(posedge clk); // GOT_S -> GOT_S where pwr_up = 1
  if (AUTH_BLK.state === GOT_S && pwr_up === 1) $display("Good6"); else $display("Bad6");

  rider_off = 1;
  repeat(2) @(posedge clk); // last received is S and rider_off = 1, GOT_S -> IDLE where pwr_up = 0
  rider_off = 0;
  if (AUTH_BLK.state === IDLE && pwr_up === 0) $display("Good7"); else $display("Bad7");

  $stop;
end

endmodule