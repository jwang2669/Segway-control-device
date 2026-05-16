module balance_cntrl_chk_tb;
logic [24:0] resp_mem [0:1499]; // memories
logic [48:0] stim_mem [0:1499];

logic clk, rst_n, pwr_up, rider_off, vld; // iDUT inputs
logic signed [15:0] ptch, ptch_rt;
logic en_steer;
logic [11:0] steer_pot;
logic too_fast; // iDUT outputs
logic signed [11:0] lft_spd, rght_spd;
balance_cntrl #(.fast_sim(1)) iDUT (
  .clk(clk), .rst_n(rst_n), .pwr_up(pwr_up), .rider_off(rider_off), .vld(vld), .ptch(ptch), .ptch_rt(ptch_rt), .en_steer(en_steer), .steer_pot(steer_pot),
  .too_fast(too_fast), .lft_spd(lft_spd), .rght_spd(rght_spd)
);

initial clk = 0;
always #5 clk = ~clk;

initial begin
  pwr_up = 0; rider_off = 0; vld = 0; ptch = 0; ptch_rt = 0; en_steer = 0; steer_pot = 0;
  rst_n = 0; @(posedge clk); @(negedge clk); rst_n = 1; // reset
  $readmemh("balance_cntrl_stim.hex", stim_mem); // read .hex into memories
  $readmemh("balance_cntrl_resp.hex", resp_mem);
  force iDUT.ss_tmr = 8'hFF;
  for (int i = 0; i < 1500; i++) begin // loop through 1500 entries in stim_mem
    rst_n     = stim_mem[i][48];
    vld       = stim_mem[i][47];
    ptch      = stim_mem[i][46:31];
    ptch_rt   = stim_mem[i][30:15];
    pwr_up    = stim_mem[i][14];
    rider_off = stim_mem[i][13];
    steer_pot = stim_mem[i][12:1];
    en_steer  = stim_mem[i][0];
    @(posedge clk) #1; // let iDUT calculate output from stimulus input
    if (lft_spd !== resp_mem[i][24:13] || rght_spd !== resp_mem[i][12:1] || too_fast !== resp_mem[i][0]) begin // comopare iDUT output to expected output in resp_mem
      $display("Mismatch at vector %0d", i);
      $display("Expected: lft_spd = %0d rght_spd=%0d too_fast = %b", resp_mem[i][24:13], resp_mem[i][12:1], resp_mem[i][0]);
      $display("Got     : lft_spd = %0d rght_spd=%0d too_fast = %b", lft_spd, rght_spd, too_fast);
      $stop;
    end
  end
  $display("All outputs match expected outputs in resp_mem.");
  $stop;
end

endmodule