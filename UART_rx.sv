module UART_rx (
  input logic clk, rst_n,
  input logic clr_rdy, RX,
  output logic rdy,
  output logic [7:0] rx_data
);

logic receiving, set_rdy, start;

// Baud Counter //
logic shift;
logic [12:0] baud_cnt;

always_ff @(posedge clk) baud_cnt <= start | shift ? (start ? 13'd2604 : 13'd5208) : (receiving ? baud_cnt - 1 : baud_cnt);

assign shift = baud_cnt == 1;

// Bit Counter /////
logic [3:0] bit_cnt;

always_ff @(posedge clk) bit_cnt <= start ? 0 : (shift ? bit_cnt + 1 : bit_cnt);

// RX Right Shift Register //
logic ff1, RX_stable;
logic [8:0] rx_shft_reg;

always_ff @(posedge clk) ff1 <= RX;
always_ff @(posedge clk) RX_stable <= ff1;
always_ff @(posedge clk) rx_shft_reg <= shift ? {RX_stable, rx_shft_reg[8:1]} : rx_shft_reg;

assign rx_data = rx_shft_reg[7:0];

// State Machine /////////////////////////
typedef enum logic {IDLE, ACTIVE} state_t;
state_t state, next_state;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) state <= IDLE;
  else state <= next_state;

always_comb begin
  next_state = IDLE;
  receiving = 0; set_rdy = 0; start = 0;
  case (state)
    IDLE:
      if (!RX_stable) begin
        next_state = ACTIVE;
        receiving = 1; set_rdy = 0; start = 1;
      end else begin
        next_state = IDLE;
        receiving = 0; set_rdy = 0; start = 0;
      end
    ACTIVE:
      if (bit_cnt == 4'd10) begin
        next_state = IDLE;
        receiving = 0; set_rdy = 1; start = 0;
      end else begin
        next_state = ACTIVE;
        receiving = 1; set_rdy = 0; start = 0;
      end
    default: begin
      next_state = IDLE;
      receiving = 0; set_rdy = 0; start = 0;
    end
  endcase
end

always @(posedge clk, negedge rst_n)
  if (!rst_n) rdy <= 0;
  else rdy <= clr_rdy || start ? 0 : (set_rdy ? 1 : rdy);

endmodule