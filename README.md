# AXI4-Lite Register Block Verification using SystemVerilog and UVM

## Overview

This project implements and verifies a 32-bit AXI4-Lite slave register block using SystemVerilog and UVM.

The DUT contains four memory-mapped registers:

- CONTROL
- STATUS
- CONFIG
- IRQ_ENABLE

The design supports independent AXI4-Lite read and write channels, byte-enable writes using WSTRB, error responses for invalid or illegal accesses, and START/BUSY/DONE control behavior.

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

Coverage-driven verification was used to identify untested protocol scenarios and develop targeted stimulus for channel ordering and backpressure conditions.

### Verification Results

- **12/12 directed tests passing**
- **0 directed-test failures**
- **0 UVM errors and 0 UVM fatals**
- **100% modeled functional coverage**
- **100% DUT line coverage**
- **86.36% DUT condition coverage**
- **All 16 WSTRB combinations exercised**
- **12 SystemVerilog assertion properties**

---

## DUT Architecture

The DUT is a 32-bit AXI4-Lite slave implementing a small memory-mapped register block.

### Register Map

| Address | Register | Access | Description |
|---------|----------|--------|-------------|
| `0x00` | CONTROL | R/W | Contains the START control bit |
| `0x04` | STATUS | R/O | Reports BUSY, DONE, and ERROR status |
| `0x08` | CONFIG | R/W | 32-bit configuration register |
| `0x0C` | IRQ_ENABLE | R/W | 32-bit interrupt-enable register |

### CONTROL Register

| Bit | Field | Access | Description |
|-----|-------|--------|-------------|
| 0 | START | R/W | Starts an operation and self-clears |
| 31:1 | Reserved | - | Unused |

### STATUS Register

| Bit | Field | Access | Description |
|-----|-------|--------|-------------|
| 0 | BUSY | R/O | Indicates an operation is in progress |
| 1 | DONE | R/O | Indicates operation completion |
| 2 | ERROR | R/O | Indicates an error condition |
| 31:3 | Reserved | R/O | Reads as zero |

### AXI4-Lite Interface

The DUT implements the five AXI4-Lite channels:

| Channel | Purpose | Signals |
|---------|---------|---------|
| Write Address | Transfers the write address | AWADDR, AWVALID, AWREADY |
| Write Data | Transfers write data and byte strobes | WDATA, WSTRB, WVALID, WREADY |
| Write Response | Returns write status | BRESP, BVALID, BREADY |
| Read Address | Transfers the read address | ARADDR, ARVALID, ARREADY |
| Read Data | Returns read data and response | RDATA, RRESP, RVALID, RREADY |

A channel transfer occurs on a rising clock edge when both `VALID` and `READY` are asserted.

The write-address and write-data channels are handled independently. The DUT captures AW and W transactions separately and performs the register write after both have been received.

The design supports backpressure on the AXI4-Lite channels and retains transaction information until the corresponding handshake completes.
