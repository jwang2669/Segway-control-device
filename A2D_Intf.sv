module A2D_Intf (
  input logic clk, rst_n, // 50MHz clock
  input logic MISO, nxt, // SPI interface / initiate A2D conversion
  output logic MOSI, SCLK, SS_n, // SPI interface / SPI interface / SPI interface
  output logic [11:0] batt, lft_ld, rght_ld, steer_pot // channel 6 result / channel 0 result / channel 4 result / channel 5 result
);

logic update, wrt;

// Round Robin Counter //
logic [1:0] rr_counter;
logic [2:0] channel;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) rr_counter <= 0;
  else rr_counter <= update ? rr_counter + 1 : rr_counter;

assign channel = rr_counter == 0 ? 0 :
                 rr_counter == 1 ? 3'd4 :
                 rr_counter == 2'd2 ? 3'd5 :
                 rr_counter == 2'd3 ? 3'd6 : 0;

// SPI_mnrch //
logic done;
logic [15:0] rd_data, wt_data;

assign wt_data = {2'd0, channel[2:0], 11'd0};

SPI_mnrch SPI_MNRCH (
  .clk(clk), .rst_n(rst_n),
  .MISO(MISO), .wrt(wrt), .wt_data(wt_data),
  .done(done), .MOSI(MOSI), .SCLK(SCLK), .SS_n(SS_n), .rd_data(rd_data)
);

always_ff @(posedge clk) batt <= update && channel == 3'd6 ? rd_data[11:0] : batt;
always_ff @(posedge clk) lft_ld <= update && channel == 0 ? rd_data[11:0] : lft_ld;
always_ff @(posedge clk) rght_ld <= update && channel == 3'd4 ? rd_data[11:0] : rght_ld;
always_ff @(posedge clk) steer_pot <= update && channel == 3'd5 ? rd_data[11:0] : steer_pot;

// State Machine ///////////////////////////////////////////////////////////////
typedef enum logic [1:0] {IDLE, TRANSACTION1, DEADPERIOD, TRANSACTION2} state_t;
state_t state, next_state;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) state <= IDLE;
  else state <= next_state;

always_comb begin
  next_state = IDLE;
  update = 0; wrt = 0;
  case (state)
    IDLE:
      if (nxt) begin
	      next_state = TRANSACTION1;
        update = 0; wrt = 1;
      end else begin
	      next_state = IDLE;
        update = 0; wrt = 0;
      end
    TRANSACTION1:
      if (done) begin
	      next_state = DEADPERIOD;
        update = 0; wrt = 0;
      end else begin
	      next_state = TRANSACTION1;
        update = 0; wrt = 0;
      end
    DEADPERIOD: begin
      next_state = TRANSACTION2;
      update = 0; wrt = 1;
    end
    TRANSACTION2:
      if (done) begin
	      next_state = IDLE;
        update = 1; wrt = 0;
      end else begin
	      next_state = TRANSACTION2;
        update = 0; wrt = 0;
      end
    default: begin
      next_state = IDLE;
      update = 0; wrt = 0;
    end
  endcase
end

endmodule