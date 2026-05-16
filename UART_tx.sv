module UART_tx (
  input logic clk, rst_n,
  input logic trmt,
  input logic [7:0] tx_data,
  output logic tx_done, TX
);

logic load, set_done, transmitting;

// Baud Counter //
logic shift;
logic [12:0] baud_cnt;

always_ff @(posedge clk) baud_cnt <= load | shift ? 0 : (transmitting ? baud_cnt + 1 : baud_cnt);

assign shift = baud_cnt == 13'd5207;

// Bit Counter /////
logic [3:0] bit_cnt;

always_ff @(posedge clk) bit_cnt <= load ? 0 : (shift ? bit_cnt + 1 : bit_cnt);

// TX Right Shift Register //
logic [8:0] tx_shft_reg;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) tx_shft_reg <= 9'b111111111;
  else tx_shft_reg <= load ? {tx_data, 1'd0} : (shift ? {1'b1, tx_shft_reg[8:1]} : tx_shft_reg);

assign TX = tx_shft_reg[0];

// State Machine /////////////////////////
typedef enum logic {IDLE, ACTIVE} state_t;
state_t state, next_state;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) state <= IDLE;
  else state <= next_state;

always_comb begin
  next_state = IDLE;
  load = 0; set_done = 0; transmitting = 0;
  case (state)
    IDLE:
      if (trmt) begin
        next_state = ACTIVE;
        load = 1; set_done = 0; transmitting = 1;
      end else begin
        next_state = IDLE;
        load = 0; set_done = 0; transmitting = 0;
      end
    ACTIVE:
      if (bit_cnt == 4'd10) begin
        next_state = IDLE;
        load = 0; set_done = 1; transmitting = 0;
      end else begin
        next_state = ACTIVE;
        load = 0; set_done = 0; transmitting = 1;
      end
    default: begin
      next_state = IDLE;
      load = 0; set_done = 0; transmitting = 0;
    end
  endcase
end

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) tx_done <= 0;
  else tx_done <= load ? 0 : (set_done ? 1 : tx_done);

endmodule