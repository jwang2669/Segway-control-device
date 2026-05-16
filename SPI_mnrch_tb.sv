module SPI_mnrch_tb ();

logic clk, rst_n, MISO, MOSI, SCLK, SS_n;
logic wrt;
logic [15:0] wt_data;
logic done;
logic [15:0] rd_data;
SPI_mnrch SPI_mnrch (.clk(clk), .rst_n(rst_n), .MISO(MISO), .MOSI(MOSI), .SCLK(SCLK), .SS_n(SS_n), .wrt(wrt), .wt_data(wt_data), .done(done), .rd_data(rd_data));
logic INT;
SPI_iNEMO1 SPI_iNEMO1 (.SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(INT));

initial clk = 0;
always #10 clk = ~clk; // 50MHz clock

// with SPI_iNEMO1, MOSI 16 bits become 1(R/!W) 2~8(address of register being read or written) 9~16(don't care if R, data being written if W)
//                  MISO 16 bits become 1~8(don't care) 9~16(data at requested register if R, don't care if W)
initial begin
  rst_n = 0;
  repeat(2) @(posedge clk); // update SS_n, done
  rst_n = 1;

  wt_data = 16'h8F00; // read register at address 0x0F with value 0x6A
  wrt = 1; repeat(2) @(posedge clk); wrt = 0;
  repeat(5) @(posedge clk); wait(done === 1);
  if ((rd_data & 16'h00FF) === 16'h006A) $display("Pass WHO_AM_I register");
  else $display("Fail WHO_AM_I register");

  wt_data = 16'h0D02; // write register at address 0x02, internal signal SPI_NEMO should go high
  wrt = 1; repeat(2) @(posedge clk); wrt = 0;
  repeat(5) @(posedge clk); wait(done === 1);

  wait(INT === 1); // INT pin goes high after neemo_setup goes high
  $display("neemo_setup goes high. INT pin goes high afterwards.");

  wt_data = 16'hA200; // read register at address 0x22 with value 0x63
  wrt = 1; repeat(2) @(posedge clk); wrt = 0;
  repeat(5) @(posedge clk); wait(done === 1);
  if ((rd_data & 16'h00FF) === 16'h0063) $display("Pass ptchL register");
  else $display("Fail ptchL register");
  
  wait(INT === 0); // INT pin is cleared when ptchL register is read
  $display("INT pin does go down after reading ptchL register");

  repeat(5) @(posedge clk);
  $stop;
end

endmodule;