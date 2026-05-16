module piezo_drv_backup #(parameter fast_sim = 1) (
  input logic clk, rst_n, // 50MHz clk
  input logic batt_low, en_steer, too_fast, // charge backwards / normal operation / priority over other inputs
  output logic piezo, piezo_n // differential piezo drive
);

localparam int signed INC = fast_sim ? 64 : 1;
typedef enum logic [2:0] {IDLE, NOTE1, NOTE2, NOTE3, NOTE4, NOTE5, NOTE6} state_t;
state_t state, next_state;
logic prev_batt_low, prev_en_steer, prev_too_fast;
logic [31:0] current_duration, current_period;

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
  else if ($signed(duration_timer) >= $signed(current_duration) - INC || state != next_state) duration_timer <= 0; // current_duration - INC might be negative / catch unconditional state transition
  else duration_timer <= duration_timer + INC;

// Repeat Timer //////////
logic [31:0] repeat_timer;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) repeat_timer <= 0;
  else if (state == IDLE && ((batt_low && (!prev_batt_low || repeat_timer >= 150000000 - INC)) || (en_steer && (!prev_en_steer || repeat_timer >= 150000000 - INC)))) repeat_timer <= 0;
  else if (state != IDLE && ((!too_fast && batt_low && (prev_too_fast || !prev_batt_low)) || (!too_fast && !batt_low && en_steer && (prev_too_fast || prev_batt_low || !prev_en_steer)))) repeat_timer <= 0;
  else if (repeat_timer >= 150000000 - INC) repeat_timer <= 0;
  else repeat_timer <= repeat_timer + INC;

// Period Timer //////////
logic [31:0] period_timer;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) period_timer <= 0;
  else if ($signed(period_timer) >= $signed(current_period) - INC || state != next_state) period_timer <= 0; // current_period - INC might be negative / catch unconditional state transition
  else period_timer <= period_timer + INC;

always_ff @(posedge clk, negedge rst_n) // for square wave output
  if (!rst_n) {piezo, piezo_n} <= 2'b01;
  else if (state == IDLE) {piezo, piezo_n} <= 2'b01; // piezo should be silent when no input signal
  else if (period_timer < (current_period >> 1)) {piezo, piezo_n} <= 2'b10; // switch piezo when timer reaches half value of note period
  else {piezo, piezo_n} <= 2'b01;

// State Machine //////////////////////
always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) state <= IDLE;
  else state <= next_state;

always_comb begin
  next_state = state;
  current_duration = 0; current_period = 0;
  case (state)
    IDLE: begin
      current_duration = 0; current_period = 0;
      if (too_fast) next_state = NOTE1;
      else if (batt_low && (!prev_batt_low || repeat_timer >= 150000000 - INC)) next_state = NOTE6; // repeat_timer = 0
      else if (en_steer && (!prev_en_steer || repeat_timer >= 150000000 - INC)) next_state = NOTE1; // repeat_timer = 0
      else next_state = IDLE;
    end NOTE1: begin
      current_duration = 1 << 23; current_period = 31887;
      if (!too_fast && !batt_low && !en_steer) next_state = IDLE;
      else if (too_fast && !prev_too_fast) next_state = NOTE1;
      else if (!too_fast && batt_low && (prev_too_fast || !prev_batt_low)) next_state = NOTE6; // repeat_timer = 0
      else if (!too_fast && !batt_low && en_steer && (prev_too_fast || prev_batt_low || !prev_en_steer)) next_state = NOTE1; // repeat_timer = 0
      else if ($signed(duration_timer) < $signed(current_duration) - INC) next_state = NOTE1; // current_duration - INC might be negative
      else if (too_fast) next_state = NOTE2;
      else if (batt_low) next_state = IDLE;
      else if (en_steer) next_state = NOTE2;
    end NOTE2: begin
      current_duration = 1 << 23; current_period = 23889;
      if (!too_fast && !batt_low && !en_steer) next_state = IDLE;
      else if (too_fast && !prev_too_fast) next_state = NOTE1;
      else if (!too_fast && batt_low && (prev_too_fast || !prev_batt_low)) next_state = NOTE6;
      else if (!too_fast && !batt_low && en_steer && (prev_too_fast || prev_batt_low || !prev_en_steer)) next_state = NOTE1;
      else if ($signed(duration_timer) < $signed(current_duration) - INC) next_state = NOTE2; // current_duration - INC might be negative
      else if (too_fast) next_state = NOTE3;
      else if (batt_low) next_state = NOTE1;
      else if (en_steer) next_state = NOTE3;
    end NOTE3: begin
      current_duration = 1 << 23; current_period = 18960;
      if (!too_fast && !batt_low && !en_steer) next_state = IDLE;
      else if (too_fast && !prev_too_fast) next_state = NOTE1;
      else if (!too_fast && batt_low && (prev_too_fast || !prev_batt_low)) next_state = NOTE6;
      else if (!too_fast && !batt_low && en_steer && (prev_too_fast || prev_batt_low || !prev_en_steer)) next_state = NOTE1;
      else if ($signed(duration_timer) < $signed(current_duration) - INC) next_state = NOTE3; // current_duration - INC might be negative
      else if (too_fast) next_state = NOTE1;
      else if (batt_low) next_state = NOTE2;
      else if (en_steer) next_state = NOTE4;
    end NOTE4: begin
      current_duration = (1 << 23) + (1 << 22); current_period = 15943;
      if (!too_fast && !batt_low && !en_steer) next_state = IDLE;
      else if (too_fast && !prev_too_fast) next_state = NOTE1;
      else if (!too_fast && batt_low && (prev_too_fast || !prev_batt_low)) next_state = NOTE6;
      else if (!too_fast && !batt_low && en_steer && (prev_too_fast || prev_batt_low || !prev_en_steer)) next_state = NOTE1;
      else if ($signed(duration_timer) < $signed(current_duration) - INC) next_state = NOTE4; // current_duration - INC might be negative
      else if (too_fast) next_state = NOTE1;
      else if (batt_low) next_state = NOTE3;
      else if (en_steer) next_state = NOTE5;
    end NOTE5: begin
      current_duration = 1 << 22; current_period = 18960;
      if (!too_fast && !batt_low && !en_steer) next_state = IDLE;
      else if (too_fast && !prev_too_fast) next_state = NOTE1;
      else if (!too_fast && batt_low && (prev_too_fast || !prev_batt_low)) next_state = NOTE6;
      else if (!too_fast && !batt_low && en_steer && (prev_too_fast || prev_batt_low || !prev_en_steer)) next_state = NOTE1;
      else if ($signed(duration_timer) < $signed(current_duration) - INC) next_state = NOTE5; // current_duration - INC might be negative
      else if (too_fast) next_state = NOTE1;
      else if (batt_low) next_state = NOTE4;
      else if (en_steer) next_state = NOTE6;
    end NOTE6: begin
      current_duration = 1 << 25; current_period = 15943;
      if (!too_fast && !batt_low && !en_steer) next_state = IDLE;
      else if (too_fast && !prev_too_fast) next_state = NOTE1;
      else if (!too_fast && batt_low && (prev_too_fast || !prev_batt_low)) next_state = NOTE6;
      else if (!too_fast && !batt_low && en_steer && (prev_too_fast || prev_batt_low || !prev_en_steer)) next_state = NOTE1;
      else if ($signed(duration_timer) < $signed(current_duration) - INC) next_state = NOTE6; // current_duration - INC might be negative
      else if (too_fast) next_state = NOTE1;
      else if (batt_low) next_state = NOTE5;
      else if (en_steer) next_state = IDLE;
     end default: begin next_state = IDLE; current_duration = 0; current_period = 0; end
  endcase
end

endmodule