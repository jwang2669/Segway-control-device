module piezo_drv #(parameter fast_sim = 1) (
  input logic clk, rst_n, // 50MHz clock
  input logic batt_low, en_steer, too_fast, // charge backwards / normal operation / priority over other inputs
  output logic piezo, piezo_n // differential piezo drive
);

localparam INC = fast_sim ? 32'd64 : 32'd1;
logic clr_duration_timer, clr_period_timer, clr_repeat_timer;
logic [31:0] curr_duration, curr_period;

//////////////////////////////////////////////////
logic prev_batt_low, prev_en_steer, prev_too_fast;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) begin
    prev_batt_low <= 0;
    prev_en_steer <= 0;
    prev_too_fast <= 0;
  end else begin
    prev_batt_low <= batt_low;
    prev_en_steer <= en_steer;
    prev_too_fast <= too_fast;
  end

// Duration Timer //////////
logic [31:0] duration_timer;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) duration_timer <= 0;
  else duration_timer <= clr_duration_timer ? 0 : duration_timer + INC;

// Period Timer //////////
logic [31:0] period_timer;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) period_timer <= 0;
  else period_timer <= clr_period_timer || period_timer >= curr_period - INC ? 0 : period_timer + INC;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) {piezo, piezo_n} <= 2'b10;
  else {piezo, piezo_n} <= period_timer < curr_period >> 1 ? 2'b10 : 2'b01;

// Repeat Timer //////////
logic [31:0] repeat_timer;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) repeat_timer <= 0;
  else repeat_timer <= clr_repeat_timer ? 0 : repeat_timer + INC;

// State Machine /////////////////////////////////////////////////////////////////
typedef enum logic [2:0] {IDLE, NOTE1, NOTE2, NOTE3, NOTE4, NOTE5, NOTE6} state_t;
state_t state, next_state;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) state <= IDLE;
  else state <= next_state;

always_comb begin
  next_state = IDLE;
  clr_duration_timer = 0; clr_period_timer = 0; clr_repeat_timer = 0; curr_duration = 0; curr_period = 0;
  case (state)
    IDLE:    begin curr_duration = 32'd1000;     curr_period = 32'd1000;  end
    NOTE1:   begin curr_duration = 32'd8388608;  curr_period = 32'd31887; end
    NOTE2:   begin curr_duration = 32'd8388608;  curr_period = 32'd23889; end
    NOTE3:   begin curr_duration = 32'd8388608;  curr_period = 32'd18960; end
    NOTE4:   begin curr_duration = 32'd12582912; curr_period = 32'd15943; end
    NOTE5:   begin curr_duration = 32'd4194304;  curr_period = 32'd18960; end
    NOTE6:   begin curr_duration = 32'd33554432; curr_period = 32'd15943; end
    default: begin curr_duration = 32'd1000;     curr_period = 32'd1000;  end
  endcase
  case (state)
    IDLE:
      if (!batt_low && !en_steer && !too_fast) begin
        next_state = IDLE;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (too_fast) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (batt_low && (!prev_batt_low || repeat_timer >= 32'd150000000 - INC)) begin
        next_state = NOTE6;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (en_steer && (!prev_en_steer || repeat_timer >= 32'd150000000 - INC)) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else begin
        next_state = IDLE;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 0;
      end
    NOTE1:
      if (!batt_low && !en_steer && !too_fast) begin
        next_state = IDLE;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (too_fast && !prev_too_fast) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (!too_fast && batt_low && (prev_too_fast || !prev_batt_low)) begin
        next_state = NOTE6;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (!too_fast && !batt_low && en_steer && (prev_too_fast || prev_batt_low || !prev_en_steer)) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (duration_timer < curr_duration - INC) begin
        next_state = NOTE1;
        clr_duration_timer = 0; clr_period_timer = 0; clr_repeat_timer = 0;
      end else if (too_fast) begin
        next_state = NOTE2;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (batt_low) begin
        next_state = IDLE;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 0;
      end else if (en_steer) begin
        next_state = NOTE2;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 0;
      end
    NOTE2:
      if (!batt_low && !en_steer && !too_fast) begin
        next_state = IDLE;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (too_fast && !prev_too_fast) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (!too_fast && batt_low && (prev_too_fast || !prev_batt_low)) begin
        next_state = NOTE6;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (!too_fast && !batt_low && en_steer && (prev_too_fast || prev_batt_low || !prev_en_steer)) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (duration_timer < curr_duration - INC) begin
        next_state = NOTE2;
        clr_duration_timer = 0; clr_period_timer = 0; clr_repeat_timer = 0;
      end else if (too_fast) begin
        next_state = NOTE3;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (batt_low) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 0;
      end else if (en_steer) begin
        next_state = NOTE3;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 0;
      end
    NOTE3:
      if (!batt_low && !en_steer && !too_fast) begin
        next_state = IDLE;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (too_fast && !prev_too_fast) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (!too_fast && batt_low && (prev_too_fast || !prev_batt_low)) begin
        next_state = NOTE6;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (!too_fast && !batt_low && en_steer && (prev_too_fast || prev_batt_low || !prev_en_steer)) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (duration_timer < curr_duration - INC) begin
        next_state = NOTE3;
        clr_duration_timer = 0; clr_period_timer = 0; clr_repeat_timer = 0;
      end else if (too_fast) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (batt_low) begin
        next_state = NOTE2;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 0;
      end else if (en_steer) begin
        next_state = NOTE4;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 0;
      end
    NOTE4:
      if (!batt_low && !en_steer && !too_fast) begin
        next_state = IDLE;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (too_fast && !prev_too_fast) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (!too_fast && batt_low && (prev_too_fast || !prev_batt_low)) begin
        next_state = NOTE6;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (!too_fast && !batt_low && en_steer && (prev_too_fast || prev_batt_low || !prev_en_steer)) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (duration_timer < curr_duration - INC) begin
        next_state = NOTE4;
        clr_duration_timer = 0; clr_period_timer = 0; clr_repeat_timer = 0;
      end else if (too_fast) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (batt_low) begin
        next_state = NOTE3;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 0;
      end else if (en_steer) begin
        next_state = NOTE5;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 0;
      end
    NOTE5:
      if (!batt_low && !en_steer && !too_fast) begin
        next_state = IDLE;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (too_fast && !prev_too_fast) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (!too_fast && batt_low && (prev_too_fast || !prev_batt_low)) begin
        next_state = NOTE6;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (!too_fast && !batt_low && en_steer && (prev_too_fast || prev_batt_low || !prev_en_steer)) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (duration_timer < curr_duration - INC) begin
        next_state = NOTE5;
        clr_duration_timer = 0; clr_period_timer = 0; clr_repeat_timer = 0;
      end else if (too_fast) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (batt_low) begin
        next_state = NOTE4;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 0;
      end else if (en_steer) begin
        next_state = NOTE6;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 0;
      end
    NOTE6:
      if (!batt_low && !en_steer && !too_fast) begin
        next_state = IDLE;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (too_fast && !prev_too_fast) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (!too_fast && batt_low && (prev_too_fast || !prev_batt_low)) begin
        next_state = NOTE6;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (!too_fast && !batt_low && en_steer && (prev_too_fast || prev_batt_low || !prev_en_steer)) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (duration_timer < curr_duration - INC) begin
        next_state = NOTE6;
        clr_duration_timer = 0; clr_period_timer = 0; clr_repeat_timer = 0;
      end else if (too_fast) begin
        next_state = NOTE1;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
      end else if (batt_low) begin
        next_state = NOTE5;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 0;
      end else if (en_steer) begin
        next_state = IDLE;
        clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 0;
      end
    default: begin
      next_state = IDLE;
      clr_duration_timer = 1; clr_period_timer = 1; clr_repeat_timer = 1;
    end
  endcase
end

endmodule