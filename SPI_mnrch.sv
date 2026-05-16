module SPI_mnrch (
  input logic clk, rst_n, // 50MHz clock
  input logic MISO, wrt, // monarch in serf out / high for 1 clock to initiate SPI transaction
  input logic [15:0] wt_data, // data to inertial sensor
  output logic done, MOSI, SCLK, SS_n, // high after SPI transaction is complete until next wrt / monarch out serf in / serial clock / active low serf select
  output logic [15:0] rd_data // data from SPI serf
);

logic init, ld_SCLK, set_done, shft;

// Bit Counter //
logic done15;
logic [3:0] bit_cntr;

always_ff @(posedge clk) bit_cntr <= init ? 0 : (shft ? bit_cntr + 1 : bit_cntr);

assign done15 = &bit_cntr;

// SCLK Divider ////
logic shft_im, smpl;
logic [3:0] SCLK_div;

always_ff @(posedge clk) SCLK_div <= ld_SCLK ? 4'b1011 : SCLK_div + 1;

assign SCLK = SCLK_div[3];
assign shft_im = SCLK_div == 4'b1111;
assign smpl = SCLK_div == 4'b0111;

// Shift Register //
logic MISO_smpl;

always_ff @(posedge clk) MISO_smpl <= smpl ? MISO : MISO_smpl;
always_ff @(posedge clk) rd_data <= init ? wt_data : (shft ? {rd_data[14:0], MISO_smpl} : rd_data);

assign MOSI = rd_data[15];

// State Machine ///////////////////////////////////////////////////////////
typedef enum logic [1:0] {IDLE, FRONT_PORCH, TRANCEIVE, BACK_PORCH} state_t;
state_t state, next_state;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) state <= IDLE;
  else state <= next_state;

always_comb begin
  next_state = IDLE;
  init = 0; ld_SCLK = 0; set_done = 0; shft = 0;
  case (state)
    IDLE:
      if (wrt) begin
        next_state = FRONT_PORCH;
        init = 1; ld_SCLK = 1; set_done = 0; shft = 0;
      end else begin
        next_state = IDLE;
        init = 0; ld_SCLK = 1; set_done = 0; shft = 0;
      end
    FRONT_PORCH:
      if (shft_im) begin
        next_state = TRANCEIVE;
        init = 0; ld_SCLK = 0; set_done = 0; shft = 0; // don't shift on first fall of SCLK
      end else begin
        next_state = FRONT_PORCH;
        init = 0; ld_SCLK = 0; set_done = 0; shft = 0;
      end
    TRANCEIVE:
      if (shft_im) begin
        next_state = TRANCEIVE;
        init = 0; ld_SCLK = 0; set_done = 0; shft = 1;
      end else if (done15 && smpl) begin
        next_state = BACK_PORCH;
        init = 0; ld_SCLK = 0; set_done = 0; shft = 0;
      end else begin
        next_state = TRANCEIVE;
        init = 0; ld_SCLK = 0; set_done = 0; shft = 0;
      end
    BACK_PORCH:
      if (shft_im) begin
        next_state = IDLE;
        init = 0; ld_SCLK = 1; set_done = 1; shft = 1;
      end else begin
        next_state = BACK_PORCH;
        init = 0; ld_SCLK = 0; set_done = 0; shft = 0;
      end
    default: begin
      next_state = IDLE;
      init = 0; ld_SCLK = 1; set_done = 0; shft = 0;
    end
  endcase
end

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) done <= 0;
  else done <= init ? 0 : (set_done ? 1 : done);

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) SS_n <= 1;
  else SS_n <= init ? 0 : (set_done ? 1 : SS_n);

endmodule