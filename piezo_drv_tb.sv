module piezo_drv_tb;

logic clk, rst_n;
logic en_steer, too_fast, batt_low;
logic piezo, piezo_n;
piezo_drv #(.fast_sim(1)) DUT (.clk(clk), .rst_n(rst_n), .en_steer(en_steer), .too_fast(too_fast), .batt_low(batt_low), .piezo(piezo), .piezo_n(piezo_n));

initial clk = 0;
always #10 clk = ~clk;

initial begin
en_steer = 0; too_fast = 0; batt_low = 0;
rst_n = 0; repeat(2) @(posedge clk) rst_n = 1;
repeat(100000) @(posedge clk);

//en_steer = 1; repeat(2500000) @(posedge clk); en_steer = 0; repeat(100000) @(posedge clk);
//too_fast = 1; repeat(2500000) @(posedge clk); too_fast = 0; repeat(100000) @(posedge clk);
//batt_low = 1; repeat(2500000) @(posedge clk); batt_low = 0; repeat(100000) @(posedge clk);

//en_steer = 1; repeat(2500000) @(posedge clk); batt_low = 1; repeat(2500000) @(posedge clk); too_fast = 1; repeat(2500000) @(posedge clk);

//en_steer = 1; repeat(500000) @(posedge clk); batt_low = 1; repeat(2500000) @(posedge clk); too_fast = 1; repeat(2500000) @(posedge clk);

en_steer = 1; repeat(2500000) @(posedge clk); batt_low = 1; repeat(2500000) @(posedge clk); too_fast = 1; repeat(2500000) @(posedge clk);
too_fast = 0; repeat(2500000) @(posedge clk); batt_low = 0; repeat(2500000) @(posedge clk); en_steer = 0; repeat(2500000) @(posedge clk);

repeat(100000) @(posedge clk);
$stop;
end

endmodule