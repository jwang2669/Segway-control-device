module Auth_blk (
  input logic clk, rst_n,
  input logic rider_off, RX,
  output logic pwr_up
);

localparam G = 8'h47, S = 8'h53;
logic clr_rx_rdy;

// UART_rx //
logic rx_rdy;
logic [7:0] rx_data;

UART_rx UART_RX (
  .clk(clk), .rst_n(rst_n),
  .clr_rdy(clr_rx_rdy), .RX(RX),
  .rdy(rx_rdy), .rx_data(rx_data)
);

// State Machine /////////////////////////////////////
typedef enum logic [1:0] {IDLE, GOT_G, GOT_S} state_t;
state_t state, next_state;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) state <= IDLE;
  else state <= next_state;

always_comb begin
  next_state = IDLE;
  clr_rx_rdy = 0; pwr_up = 0;
  case (state)
    IDLE:
      if (rx_rdy && rx_data == G) begin
        next_state = GOT_G;
        clr_rx_rdy = 1; pwr_up = 1;
      end else begin
        next_state = IDLE;
        clr_rx_rdy = 0; pwr_up = 0;
      end
    GOT_G:
      if (rx_rdy && rx_data == S) begin
        next_state = GOT_S;
        clr_rx_rdy = 1; pwr_up = 1;
      end else begin
        next_state = GOT_G;
        clr_rx_rdy = 0; pwr_up = 1;
      end
    GOT_S:
      if (rx_rdy && rx_data != S) begin
        next_state = GOT_G;
        clr_rx_rdy = 1; pwr_up = 1;
      end else if (rider_off) begin
        next_state = IDLE;
        clr_rx_rdy = 0; pwr_up = 0;
      end else begin
        next_state = GOT_S;
        clr_rx_rdy = 0; pwr_up = 1;
      end
    default: begin
      next_state = IDLE;
      clr_rx_rdy = 0; pwr_up = 0;
    end
  endcase
end

endmodule