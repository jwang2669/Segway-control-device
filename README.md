# Self-Balancing “Segway” Controller

A complete FPGA-based digital control system for a self-balancing two-wheel platform implemented in **SystemVerilog**.

This project integrates:

* UART-based Bluetooth authentication
* SPI communication with inertial sensor and ADC
* Sensor fusion using gyro + accelerometer data
* PID balance control
* Steering control
* Motor PWM drive logic
* Piezo warning/audio system
* Full-chip verification and synthesis flow

---

# Overview

The system controls a wooden “Segway”-style balancing platform using:

* Independent left/right motor drive
* Inertial measurement feedback
* Rider weight/load cell sensing
* Steering potentiometer input
* Bluetooth authorization
* Battery monitoring
* Safety and warning systems

The design targets FPGA synthesis and was verified through:

* RTL simulation
* Post-synthesis simulation
* Full-system testbench integration
* Hardware demonstration on the physical platform

---

# Top-Level Architecture

```text
                 +-------------------+
                 |     Segway.sv     |
                 +-------------------+
                     |           |
        +------------+           +-------------+
        |                                        |
+---------------+                     +----------------+
|  auth_blk     |                     | balance_cntrl |
+---------------+                     +----------------+
        |                                        |
        |                                        |
        v                                        v
+---------------+                     +----------------+
| inert_intf    |<----SPI----->       |   mtr_drv      |
+---------------+                     +----------------+
        |
        v
+----------------------+
| inertial_integrator  |
+----------------------+

+---------------+
| A2D_intf      |
+---------------+

+---------------+
| piezo_drv     |
+---------------+
```

---

# Features

## Bluetooth Authentication (`auth_blk`)

* UART receiver operating at **19200 baud, 8N1**
* Powers system ON upon receiving:

  * `'G'` (`0x47`)
* Powers system OFF when:

  * `'S'` (`0x53`) received
  * rider is no longer detected

---

## SPI Controller (`SPI_mnrch`)

Custom SPI master supporting:

* 16-bit transactions
* SCLK = `clk / 16`
* MOSI shifted on falling edge
* MISO sampled on rising edge

Used for:

* Inertial sensor communication
* ADC communication

---

## Inertial Sensor Interface (`inert_intf`)

Reads:

* Pitch rate from gyro
* Z-axis acceleration from accelerometer

Performs:

* Sensor initialization
* Continuous data acquisition
* Interrupt-driven reads

---

## Sensor Fusion (`inertial_integrator`)

Combines:

* Integrated gyro pitch
* Accelerometer pitch estimate

Fusion algorithm reduces:

* Gyro drift
* Accelerometer noise

Implements:

```text
ptch_int <= ptch_int
          - ptch_rt_comp
          + fusion_ptch_offset
```

---

## PID Balance Controller

Implements:

* Proportional control
* Integral accumulation
* Derivative damping

Controls:

* Left motor torque
* Right motor torque

Supports:

* Soft-start ramp
* Steering compensation
* Dead-zone motor shaping

---

## Steering Enable Logic (`en_steer`)

Uses:

* Load cell balancing
* Rider weight detection
* Time hysteresis

Enables steering only when:

* Rider weight exceeds threshold
* Weight distribution is balanced

---

## ADC Interface (`A2D_intf`)

Round-robin conversion of:

* Left load cell
* Right load cell
* Steering potentiometer
* Battery voltage

Communicates using SPI to ADC128S022 model.

---

## Motor Driver (`mtr_drv`)

Handles:

* PWM generation
* Direction control
* Overcurrent shutdown protection

Uses:

* Dual `PWM11` modules

---

## Piezo Driver (`piezo_drv`)

Generates:

* Charge fanfare
* Overspeed warning
* Low battery warning

Supports:

* `fast_sim` mode for accelerated simulation

---

# Verification

## Testbenches

Comprehensive verification included for:

* UART receiver
* SPI master
* ADC interface
* Piezo driver
* Steering enable FSM
* Full-chip integration

---

## Post-Synthesis Validation

Verified:

* Gate-level netlist functionality
* Timing correctness
* Full-chip operation after synthesis

---

# Synthesis

Target constraints:

| Constraint   | Value   |
| ------------ | ------- |
| Clock Period | 3ns     |
| Frequency    | 333 MHz |
| Input Delay  | 0.25ns  |
| Output Delay | 0.35ns  |
| Output Load  | 50fF    |

Additional requirements:

* Hierarchy flattened
* `compile_ultra` not used
* Area optimization emphasized

---

# Project Structure

```text
├── rtl/
│   ├── Segway.sv
│   ├── auth_blk.sv
│   ├── UART_rcv.sv
│   ├── SPI_mnrch.sv
│   ├── inert_intf.sv
│   ├── inertial_integrator.sv
│   ├── balance_cntrl.sv
│   ├── A2D_intf.sv
│   ├── piezo_drv.sv
│   ├── mtr_drv.sv
│   └── ...
│
├── tb/
│   ├── Segway_tb.sv
│   ├── piezo_drv_tb.sv
│   ├── SPI_mnrch_tb.sv
│   └── ...
│
├── models/
│   ├── SegwayModel.sv
│   ├── ADC128S_FC.v
│   └── SPI_ADC128S.sv
│
├── synthesis/
│   ├── synth.tcl
│   └── Segway.vg
│
└── README.md
```

---

# Running Simulation

Example with ModelSim:

```bash
vlog rtl/*.sv
vlog tb/*.sv
vsim Segway_tb
run -all
```

---

# Running Synthesis

Example:

```bash
dc_shell -f synth.tcl
```

Outputs:

* Gate-level netlist (`Segway.vg`)
* Timing reports
* Area reports

---
