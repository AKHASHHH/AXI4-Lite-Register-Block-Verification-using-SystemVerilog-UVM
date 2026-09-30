# AXI4-Lite Register Block Verification using SystemVerilog and UVM

## Overview

This project implements and verifies a 32-bit AXI4-Lite slave register block using SystemVerilog and the Universal Verification Methodology (UVM).

The DUT contains four memory-mapped registers:

- `CONTROL`
- `STATUS`
- `CONFIG`
- `IRQ_ENABLE`

The design supports independent AXI4-Lite read and write channels, byte-enable writes using `WSTRB`, error responses for invalid or illegal accesses, and START/BUSY/DONE control behavior.

The verification environment combines:

- Directed testing
- Constrained-random stimulus
- Negative testing
- SystemVerilog Assertions (SVA)
- Functional coverage
- Code coverage
- Self-checking scoreboard
- UVM Register Abstraction Layer (RAL)
- Automated regression using Synopsys VCS and URG

Coverage-driven verification was used to identify missing scenarios and develop targeted legal stimulus. Coverage closure was evaluated alongside protocol assertions rather than treating coverage percentage alone as proof of correctness.

---

## Verification Results

The final clean regression achieved:

| Metric | Result |
|---|---:|
| Directed tests | **12/12 passed** |
| Directed-test failures | **0** |
| UVM errors | **0** |
| UVM fatals | **0** |
| RAL UVM errors / fatals | **0 / 0** |
| SVA failures | **0** |
| Modeled functional coverage | **100%** |
| DUT line coverage | **100%** |
| DUT branch coverage | **93.94%** |
| DUT condition coverage | **72.73%** |
| WSTRB values exercised | **16/16** |
| SVA properties | **12** |

Functional coverage refers specifically to the implemented verification coverage model and does not imply that every possible DUT behavior has been exhaustively verified.

---

## DUT Architecture

The DUT is a 32-bit AXI4-Lite slave implementing a small memory-mapped register block.

### Register Map

| Address | Register | Access | Description |
|---|---|---|---|
| `0x00` | CONTROL | R/W | Contains the START control bit |
| `0x04` | STATUS | R/O | Reports BUSY, DONE, and ERROR status |
| `0x08` | CONFIG | R/W | 32-bit configuration register |
| `0x0C` | IRQ_ENABLE | R/W | 32-bit interrupt-enable register |

### CONTROL Register

| Bit | Field | Access | Description |
|---|---|---|---|
| 0 | START | R/W | Starts an operation and self-clears |
| 31:1 | Reserved | - | Unused |

### STATUS Register

| Bit | Field | Access | Description |
|---|---|---|---|
| 0 | BUSY | R/O | Indicates an operation is in progress |
| 1 | DONE | R/O | Indicates operation completion |
| 2 | ERROR | R/O | Indicates an error condition |
| 31:3 | Reserved | R/O | Reads as zero |

---

## AXI4-Lite Interface

The DUT implements the five AXI4-Lite channels:

| Channel | Purpose | Signals |
|---|---|---|
| Write Address | Transfers the write address | `AWADDR`, `AWVALID`, `AWREADY` |
| Write Data | Transfers write data and byte strobes | `WDATA`, `WSTRB`, `WVALID`, `WREADY` |
| Write Response | Returns write status | `BRESP`, `BVALID`, `BREADY` |
| Read Address | Transfers the read address | `ARADDR`, `ARVALID`, `ARREADY` |
| Read Data | Returns read data and response | `RDATA`, `RRESP`, `RVALID`, `RREADY` |

A channel transfer occurs on a rising clock edge when both `VALID` and `READY` are asserted.

The write-address and write-data channels are handled independently. The DUT captures AW and W transactions separately and performs the register write after both have been received.

The implementation supports:

- AW-before-W transactions
- W-before-AW transactions
- Write-response backpressure
- Read-response backpressure
- Partial writes using `WSTRB`
- Invalid-address handling
- Read-only register protection
- Reset and post-reset recovery

Successful accesses return `OKAY (2'b00)`. Invalid or illegal accesses return `SLVERR (2'b10)`.

---

# Verification Architecture

The verification environment was developed using UVM with separate components for stimulus generation, protocol driving, monitoring, checking, functional coverage, and register-model prediction.

Conceptually, the environment follows:

```text
                         +------------------+
                         |    Sequences     |
                         +--------+---------+
                                  |
                                  v
                         +------------------+
                         |    Sequencer     |
                         +--------+---------+
                                  |
                                  v
                         +------------------+
                         |      Driver      |
                         +--------+---------+
                                  |
                                  v
                         +------------------+
                         | AXI-Lite Interface|
                         +--------+---------+
                                  |
                                  v
                         +------------------+
                         |       DUT        |
                         +--------+---------+
                                  |
                                  v
                         +------------------+
                         |     Monitor      |
                         +----+--------+----+
                              |        |
                    +---------+        +-----------+
                    v                              v
             +-------------+                +-------------+
             | Scoreboard  |                |  Coverage   |
             +-------------+                +-------------+
                    |
                    +--------------------+
                                         |
                                         v
                                +-----------------+
                                | RAL Predictor   |
                                +-----------------+

                   SVA assertions observe protocol
                   and functional behavior directly.
```

---

## UVM Components

### Sequence Item

The AXI-Lite transaction object represents a protocol operation and contains fields including:

- Operation type: read or write
- Address
- Write data
- Write strobe
- Response

Constraints generate legal register accesses during normal constrained-random testing.

Illegal operations are generated explicitly by negative-test sequences rather than weakening the legal constraints used by the normal stimulus.

### Sequences

The environment includes stimulus for:

- Constrained-random register transactions
- Invalid-address accesses
- Writes to the read-only STATUS register
- Partial writes
- All 16 possible `WSTRB` values
- Register-model accesses

This allows broad random exploration while retaining targeted control over important corner cases.

### Sequencer

The sequencer arbitrates sequence items and supplies transactions to the AXI-Lite driver.

### Driver

The driver converts transaction-level sequence items into pin-level AXI4-Lite activity.

It independently drives the write-address, write-data, write-response, read-address, and read-data channel handshakes according to the transaction being executed.

### Monitor

The monitor passively observes completed AXI4-Lite transactions.

Observed transactions are distributed through analysis ports to:

- The scoreboard
- Functional coverage collector
- UVM RAL predictor

This ensures checking and coverage are based on activity actually observed on the DUT interface rather than only on intended stimulus.

### Scoreboard

The scoreboard maintains a reference model of expected register state and compares predicted behavior against transactions observed by the monitor.

Checks include:

- Register write/readback consistency
- Partial `WSTRB` writes
- Read-only STATUS behavior
- Invalid-address behavior
- AXI response values

### Functional Coverage

Functional coverage tracks:

- Read versus write operations
- Register addresses
- AXI response types
- All 16 `WSTRB` values
- Operation × address cross coverage

The final clean regression closed all modeled functional coverage bins.

---

# UVM Register Abstraction Layer

A UVM RAL model was implemented for the complete register map.

The model represents:

- CONTROL
- STATUS
- CONFIG
- IRQ_ENABLE

Register fields include their corresponding:

- Address
- Width
- Access policy
- Reset value
- Volatility where applicable

The environment also includes:

### RAL Adapter

The adapter converts generic UVM register operations into AXI-Lite sequence items and translates observed bus responses back into UVM register transactions.

### RAL Predictor

The predictor receives transactions from the AXI-Lite monitor and updates the register-model mirror based on activity observed on the bus.

### RAL Verification

Dedicated RAL testing exercises front-door register accesses through the AXI-Lite interface.

The final RAL regression completed with:

```text
UVM_ERROR : 0
UVM_FATAL : 0
```

---

# SystemVerilog Assertions

Twelve SVA properties are used to check protocol and functional behavior.

The assertions cover areas including:

- B-channel response stability during backpressure
- R-channel response stability during backpressure
- AW address stability while stalled
- W data and strobe stability while stalled
- AR address stability while stalled
- Write-response generation
- Read-response generation
- Reset behavior
- START-to-BUSY behavior
- START self-clear behavior
- BUSY-to-DONE behavior
- DONE/BUSY consistency

Assertions run alongside directed and regression testing.

The final clean directed regression completed with **zero SVA assertion failures**.

---

# Directed Verification

Twelve directed tests exercise specific DUT behaviors and protocol corner cases.

| Test | Scenario |
|---:|---|
| 1 | CONFIG write/read |
| 2 | IRQ_ENABLE write/read |
| 3 | Partial `WSTRB` write |
| 4 | Invalid write address |
| 5 | Invalid read address |
| 6 | START → BUSY → DONE behavior and START self-clear |
| 7 | STATUS read-only protection |
| 8 | W channel arriving before AW |
| 9 | AW channel arriving before delayed W |
| 10 | B-channel backpressure |
| 11 | R-channel backpressure |
| 12 | Reset and post-reset recovery |

Final result:

```text
Tests passed = 12
Failures     = 0

ALL 12 DIRECTED TESTS PASSED
```

---

# Constrained-Random and Negative Testing

The UVM environment supplements directed tests with constrained-random stimulus.

Normal constrained-random transactions target legal register accesses, while dedicated negative sequences intentionally exercise illegal behavior such as:

- Invalid write addresses
- Invalid read addresses
- Writes to the read-only STATUS register

Separating legal constrained-random stimulus from explicit negative testing makes the intent of each transaction clear and simplifies debugging and coverage analysis.

---

# Coverage Strategy

Coverage was treated as a feedback mechanism rather than simply a final percentage.

The verification flow used:

1. Directed testing to establish basic functionality.
2. Constrained-random testing to exercise varied register traffic.
3. Functional coverage to identify missing scenarios.
4. Negative sequences to exercise error responses and illegal accesses.
5. Targeted `WSTRB` stimulus to exercise all byte-enable combinations.
6. Code-coverage analysis to identify remaining implementation-level holes.
7. SVA to ensure coverage-oriented stimulus remained protocol-correct.

Increasing random transaction volume alone was not treated as a substitute for targeted coverage closure. Missing scenarios were analyzed before additional stimulus was introduced.

---

# Coverage Results

## Functional Coverage

The final regression achieved **100% modeled functional coverage**.

- `cp_operation`: **2/2 bins covered**
- `cp_addr`: **4/4 bins covered**
- `cp_resp`: **2/2 bins covered**
- `cp_strb`: **16/16 bins covered**
- Operation × address cross: **8/8 bins covered**

![Functional Coverage](docs/images/functional_coverage.png)

The functional coverage result represents closure of the implemented coverage model and should not be interpreted as proof that every theoretically possible DUT behavior has been exhausted.

---

## DUT Code Coverage

The final clean DUT code-coverage results were:

| Metric | Coverage |
|---|---:|
| Line | **100.00%** |
| Branch | **93.94%** |
| Condition | **72.73%** |
| Toggle | **48.01%** |

All **71/71 executable DUT lines** were exercised.

![DUT Code Coverage](docs/images/dut_code_coverage.png)

Condition and toggle coverage were reviewed separately rather than using the aggregate coverage score as the sole measure of verification quality.

---

# Regression Results

The final regression completed cleanly across the directed, UVM, RAL, and assertion-based verification flows.

![Regression Results](docs/images/regression_results.png)

Final sign-off status:

```text
Directed tests : 12/12 passed
Directed failures : 0

UVM_ERROR : 0
UVM_FATAL : 0

RAL UVM_ERROR : 0
RAL UVM_FATAL : 0

SVA assertion failures : 0
```

---

# Verification and Debugging Highlights

Several issues encountered during development required debugging of both the DUT-facing environment and the verification infrastructure itself.

Examples included:

- Debugging VALID/READY timing in the AXI-Lite driver.
- Verifying independent AW and W channel ordering.
- Detecting and correcting a directed-test checker path that reported a failure without incrementing the failure counter.
- Debugging stale VCS incremental-build state during coverage regression.
- Using functional coverage to identify missing response and `WSTRB` scenarios.
- Evaluating targeted coverage stimulus against SVA to ensure coverage was not increased using protocol-invalid behavior.

These debugging steps reinforced the distinction between simply generating stimulus and building a self-checking verification environment capable of detecting errors in both the DUT and the testbench.

---

# Project Structure

```text
AXI-Lite-UVM-Verification/
│
├── rtl/
│   └── axi_lite_regs.sv
│
├── tb/
│   ├── axi_lite_if.sv
│   ├── axi_lite_pkg.sv
│   ├── axi_lite_seq_item.sv
│   ├── axi_lite_sequence.sv
│   ├── axi_lite_sequencer.sv
│   ├── axi_lite_driver.sv
│   ├── axi_lite_monitor.sv
│   ├── axi_lite_scoreboard.sv
│   ├── axi_lite_agent.sv
│   ├── axi_lite_coverage.sv
│   ├── axi_lite_env.sv
│   ├── axi_lite_test.sv
│   ├── axi_lite_ral_test.sv
│   ├── tb_axi_lite_regs.sv
│   └── tb_axi_lite_uvm_top.sv
│
├── assertions/
│   └── axi_lite_assertions.sv
│
├── ral/
│   ├── axi_lite_reg_model.sv
│   └── axi_lite_reg_adapter.sv
│
├── scripts/
│   └── run_regression.csh
│
├── docs/
│   └── images/
│       ├── dut_code_coverage.png
│       ├── functional_coverage.png
│       └── regression_results.png
│
├── .gitignore
└── README.md
```

---

# Running the Verification Environment

The project was developed and tested using:

- SystemVerilog
- UVM
- Synopsys VCS
- Synopsys URG
- Synopsys Verdi

The regression script compiles and runs:

1. Directed verification
2. UVM constrained-random and negative testing
3. Code and functional coverage collection
4. Coverage database merge and URG report generation
5. Dedicated UVM RAL testing

Example:

```tcsh
./scripts/run_regression.csh
```

The exact Synopsys installation and environment setup is system-dependent and may require modification for a different workstation or EDA environment.

---

# Key Concepts Demonstrated

This project demonstrates practical experience with:

- AXI4-Lite protocol verification
- SystemVerilog
- UVM architecture
- Constrained-random verification
- Directed and negative testing
- Self-checking scoreboards
- SystemVerilog Assertions
- Functional coverage
- Code coverage analysis
- Coverage-driven verification
- UVM Register Abstraction Layer
- Register prediction
- AXI backpressure
- Independent AW/W channel handling
- Partial writes using `WSTRB`
- Error-response verification
- Automated regression
- Verification debugging

---

## Conclusion

This project demonstrates an end-to-end verification flow for a 32-bit AXI4-Lite register block.

The final environment combines directed testing, constrained-random stimulus, negative testing, SVA, functional and code coverage, a self-checking scoreboard, UVM RAL, and automated regression.

The clean final regression passed all 12 directed tests with zero UVM errors, zero UVM fatals, zero SVA assertion failures, and closed all modeled functional coverage bins while achieving 100% DUT line coverage and 93.94% branch coverage.
