# Multi-Slave SPI Master Controller in Verilog HDL

A configurable, FSM-based Serial Peripheral Interface (SPI) master controller, implemented in Verilog HDL and verified through simulation. The controller drives a single shared SPI bus (`SCLK`, `MOSI`, `MISO`) to communicate with three heterogeneous slave devices — an SPI FLASH memory, a digital temperature sensor, and an OLED display driver — using independent, arbitrated chip-select lines.

> Based on the accompanying report: *"Design, Implementation, and Verification of a Multi-Slave SPI Master Controller in Verilog HDL"* — Raham Dil, Department of Computer Engineering, Ghulam Ishaq Khan Institute of Engineering Science and Technology.

---

## Overview

Dedicating a full SPI master to every peripheral quickly becomes impractical on small, area-constrained FPGAs. This project implements a **single shared SPI master core** that arbitrates access across multiple slaves on the same physical bus, giving each device its own dedicated chip-select while multiplexing `SCLK`, `MOSI`, and `MISO`.

The design targets **SPI Mode 0** (CPOL = 0, CPHA = 0), the most widely supported mode across FLASH, sensor, and display peripherals.

### Key Features

- FSM-based master controller separating protocol-level timing (clock generation, bit shifting) from device-level control (chip-select arbitration, command/data selection)
- Support for **3 slave peripherals** on a shared bus:
  - SPI FLASH memory (non-volatile storage)
  - Digital temperature sensor (environmental monitoring)
  - OLED display controller (visual output, with dedicated `OLED_DC` command/data signaling)
- Simple handshake interface (`start`, `busy`, `done`) for integration with a higher-level board/system controller
- Self-checking, waveform-verified simulation testbench
- Low resource footprint suitable for small FPGAs and embedded SoC integration

---

## Architecture

A top-level board controller instantiates a single SPI master core and multiplexes its bus signals to the three peripherals via a 2-bit `slave_select` signal.

### Top-Level Signals

| Signal        | Direction | Description                                      |
|---------------|-----------|---------------------------------------------------|
| `clk`         | In        | System clock driving the master FSM               |
| `rst`         | In        | Active-high synchronous reset                      |
| `start`       | In        | Pulses high to initiate a transaction              |
| `slave_select`| In        | Selects target slave (0 = FLASH, 1 = TEMP, 2 = OLED) |
| `master_tx`   | In        | Byte to be transmitted to the slave                |
| `master_rx`   | Out       | Byte received from the slave                       |
| `busy`        | Out       | High while a transaction is in progress            |
| `done`        | Out       | Single-cycle pulse at transaction completion       |
| `BOARD_SCLK`  | Out       | Shared serial clock to all slaves                  |
| `BOARD_MOSI`  | Out       | Shared master-out data line                        |
| `BOARD_MISO`  | In        | Shared master-in data line                         |
| `FLASH_CS_N`  | Out       | Active-low chip select for FLASH                   |
| `TEMP_CS_N`   | Out       | Active-low chip select for temperature sensor      |
| `OLED_CS_N`   | Out       | Active-low chip select for OLED                    |
| `OLED_DC`     | Out       | Data/Command select line for OLED                  |

### Master FSM

The master core is a Moore-type finite state machine with four states:

1. **IDLE** — `busy` low, all chip-selects de-asserted; waits for `start`, latches `slave_select` and `master_tx`.
2. **CS_ASSERT** — Decoded chip-select line driven low, `busy` asserted, setup delay inserted before clocking.
3. **SHIFT_DATA** — `BOARD_SCLK` toggles at half the system clock rate; outgoing bits placed on `BOARD_MOSI` on rising edges, incoming bits sampled from `BOARD_MISO` on falling edges, until 8 bits are transferred.
4. **CS_DEASSERT** — Chip-select returned high, shift register latched onto `master_rx`, `done` pulsed for one cycle, then returns to IDLE.

Timing margins (chip-select setup/hold, one system-clock cycle per SCLK half-period) are chosen conservatively to satisfy the setup/hold requirements of the target FLASH and OLED datasheets, adding a fixed overhead of two clock cycles per transaction on top of the eight bit-periods needed to shift a byte.

---

## Repository Structure

```
.
├── rtl/                  # Verilog source (master core, slave-select decoder, peripheral wrappers)
├── tb/                   # Self-checking simulation testbench
├── sim/                  # Simulation scripts / waveform dumps
├── docs/                 # Report, schematics, and waveform screenshots
└── README.md
```

*(Adjust to match your actual folder layout.)*

---

## Verification

Verification was performed with a directed, self-checking testbench that applies a synchronous reset and issues four back-to-back transactions, one per target device/mode:

| Txn # | Target Slave      | `slave_select` | `master_tx` | `master_rx` | Active CS      | Notes                          |
|-------|--------------------|:--------------:|:-----------:|:-----------:|-----------------|----------------------------------|
| 1     | FLASH Memory        | 0               | `8'hA5`     | `8'h80`     | `FLASH_CS_N`    | Write-then-read                 |
| 2     | Temperature Sensor  | 1               | `8'h9C`     | `8'h00`     | `TEMP_CS_N`     | Sensor read                     |
| 3     | OLED (command)      | 2               | `8'h3F`     | `8'h80`     | `OLED_CS_N`     | `OLED_DC` = 0 (command)          |
| 4     | OLED (pixel data)   | 2               | `8'hFF`     | `8'h80`     | `OLED_CS_N`     | `OLED_DC` = 1 (pixel data)       |

The testbench checks, for every transaction:

- `busy` asserts within one clock cycle of `start` and stays high for the full 8-bit shift
- Exactly one chip-select line is low at a time, matching the latched `slave_select`
- `BOARD_SCLK` produces exactly 8 pulses per transaction
- `master_rx` holds a valid, defined value (no unresolved `X`/`Z`) once `done` asserts
- `done` pulses for exactly one clock cycle
- `OLED_DC` reflects command vs. pixel-data phase correctly

### Defects Found and Fixed

| Defect | Root Cause | Fix |
|---|---|---|
| High-impedance (`Z`) glitch on `master_rx` | Shift register read one cycle before the final MISO bit was latched | Re-timed the `master_rx` assignment to the `CS_DEASSERT` state |
| `OLED_CS_N` not toggling on OLED transactions | Incomplete `case` statement in the chip-select decoder missing the `slave_select = 2` branch | Added the missing case |

### Verification Checklist Results

| Check Item                  | Transactions Checked | Result |
|------------------------------|:---------------------:|:------:|
| Correct CS_N assertion        | 4/4                    | Pass   |
| 8 SCLK pulses per byte         | 4/4                    | Pass   |
| No X/Z on `master_rx`          | 4/4                    | Pass   |
| `done` pulse width = 1 cycle   | 4/4                    | Pass   |
| `OLED_DC` correctness          | 2/2                    | Pass   |
| `busy` assertion timing        | 4/4                    | Pass   |

<img src="images/spi_master_controller.png" alt="Multi-Slave SPI Master Controller" width="800"/>
<img src="images/spi_master_controller.png" alt="Multi-Slave SPI Master Controller" width="800"/>
<img src="images/spi_master_controller.png" alt="Multi-Slave SPI Master Controller" width="800"/>

### Functional Coverage

All functionally relevant coverage bins were hit at 100%, with one intentionally open item — a mid-transfer asynchronous reset scenario — left for a future constrained-random regression suite.

Simulation used a 100 MHz (10 ns period) system clock, giving a ~20.24 µs window in which all four transactions complete with idle time between them.

---

## Synthesis Results

Representative post-synthesis figures for a low-cost 28 nm FPGA target (default optimization, no aggressive constraints):

| Resource            | Used   | Utilization |
|----------------------|:------:|:-----------:|
| Look-Up Tables (LUT)  | 142    | < 1%        |
| Flip-Flops (FF)       | 96     | < 1%        |
| I/O Pins              | 21     | —           |
| Block RAM             | 0      | 0%          |
| Max. clock frequency  | 187 MHz| —           |

The design uses only shift registers, comparators, and a 4-state FSM (no FIFOs or DSP blocks), giving a small area footprint and ample timing margin over the target peripherals' SPI clock requirements (all well below 50 MHz).

---

## Getting Started

### Prerequisites

- A Verilog simulator (e.g., Icarus Verilog, ModelSim, Verilator, or Vivado Simulator)
- (Optional) An FPGA toolchain for synthesis (e.g., Vivado, Quartus, Yosys)

### Running the Simulation

```bash
# Example using Icarus Verilog
iverilog -o sim_out rtl/*.v tb/tb_spi_master.v
vvp sim_out
```

Adjust source paths to match your repository layout. Waveform dumps (`.vcd`) can be viewed with GTKWave or your simulator's waveform viewer.

---

## Future Work

- Configurable SPI modes (CPOL/CPHA)
- Variable data widths beyond 8 bits
- Multi-byte burst transfers under a single chip-select assertion
- Formal property verification using SystemVerilog Assertions (SVA), including:
  - Mutual exclusivity of chip-select lines
  - Absence of unresolved (`X`/`Z`) values on the readback bus at `done`
- Back-annotated gate-level timing simulation and on-hardware validation with a logic analyzer
- Constrained-random regression testing, including the currently uncovered mid-transfer reset scenario

---

## References

1. Motorola Inc., "SPI Block Guide V03.06," Freescale Semiconductor Reference Manual, 2003.
2. P. Bhatt and N. Trivedi, "Design and Implementation of SPI Protocol Using Verilog HDL," *International Journal of Engineering Research and Technology*, vol. 4, no. 5, 2015.
3. S. Palnitkar, *Verilog HDL: A Guide to Digital Design and Synthesis*, 2nd ed. Prentice Hall, 2003.
4. J. Bhasker, *Verilog HDL Synthesis: A Practical Primer*. Star Galaxy Publishing, 1998.
5. M. Zwolinski, *Digital System Design with SystemVerilog*. Prentice Hall, 2010.
6. IEEE Standard for SystemVerilog, IEEE Std 1800-2017, IEEE, 2017.
7. Microchip Technology, "SST25VF Series SPI Serial Flash Memory Datasheet," 2013.
8. Solomon Systech, "SSD1306 OLED Driver IC Datasheet," 2008.

---

## Author

**Raham Dil**
Department of Computer Engineering
Ghulam Ishaq Khan Institute of Engineering Science and Technology
u2024529@giki.edu.pk

## License

Specify a license for this project (e.g., MIT, Apache 2.0) — add a `LICENSE` file to the repository root.

