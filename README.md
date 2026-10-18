# PCIe Gen 3 Data Link Layer Controller & UVM Verification Environment

## 📌 Project Overview
This repository contains a synthesizable SystemVerilog implementation of a **PCIe Gen 3 Data Link Layer (DLL)** engine alongside a complete, constrained-random verification environment developed using **Universal Verification Methodology (UVM 1.2)**.

The Data Link Layer guarantees reliable point-to-point packet delivery across noisy high-speed interconnects using sequence tracking, 32-bit Link CRC (LCRC) verification, and an automatic ACK/NAK Replay Buffer.

---

## 🏗️ Architecture & Features

### 1. Hardware Blocks (Synthesizable RTL)
* **Byte-Parallel LCRC-32 Calculator (`pcie_crc32.sv`)**:
  * Implements the standardized PCIe CRC polynomial ($x^{32} + x^{26} + x^{23} + ... + 1$, `0x04C11DB7`).
  * Combinatorial 8-bit parallel architecture calculating one payload byte per cycle.
* **TX Engine & Replay Buffer (`pcie_tx_engine.sv`)**:
  * Automatically assigns a monotonic 12-bit sequence number to incoming TLPs.
  * Dynamically calculates and appends the 32-bit LCRC trailer.
  * Implements a parameterized circular replay buffer retaining unacknowledged packets.
* **RX Engine & Checker (`pcie_rx_engine.sv`)**:
  * Parses incoming frames and unpacks sequence numbers.
  * Re-calculates LCRC in real-time, discarding corrupted packets before upstream delivery.
  * Automatically transmits ACK or NAK Data Link Layer Packets (DLLPs).
* **Top-Level Controller (`pcie_dll_top.sv`)**:
  * Full-duplex interconnect routing TX, RX, and feedback paths.

---

## 🧪 UVM Verification Architecture

The verification environment exercises positive transactions and negative corner cases:


### Verification Capabilities
* **Constrained-Random Stimulus**: Randomized packet lengths, variable inter-packet delays, and configurable error-injection distributions.
* **Negative Testing**: Deliberately injects flipped CRC bits and out-of-order sequence IDs to verify NAK generation and automatic replay buffer retransmission.
* **Scoreboard Closure**: Dynamic end-to-end packet tracking and error-accounting reports.

---

## 🚀 How to Run Simulation

### Option 1: Automated Multi-Seed Regression 
bash,
cd sim,
python run.py

### Option 2 
cd sim,
make compile,
make run TESTNAME=pcie_test SEED=42,
make wave


###  Testing on EDA Playground (Zero-Install Path)

If you don't have Synopsys VCS or Siemens Questa installed locally on your Windows machine:
1. Open [EDA Playground](https://www.edaplayground.com).
2. On the left sidebar:
   * **Tools & Simulators:** Select **Aldec Riviera-PRO** (or **Synopsys VCS** if enabled).
   * **UVM / OVM:** Select **UVM 1.2**.
   * Check **Open EPWave after run** to view waveforms.
3. In the left editor pane (**testbench.sv**), paste the contents of `tb/tb_top.sv`.
4. In the right editor pane (**design.sv**), paste the contents of `rtl/pcie_crc32.sv`, `rtl/pcie_tx_engine.sv`, `rtl/pcie_rx_engine.sv`, and `rtl/pcie_dll_top.sv`.
5. Click **Run**. The console will compile the code, start the UVM sequence, output the scoreboard summary report, and open the interactive waveform viewer.

Save the three files (`sim/run.py`, `sim/Makefile`, and `README.md`). 

## 📊 Simulation Waveform

Below is the EPWave simulation trace showing 5 back-to-back TLP packet transmissions, LCRC calculation, framing (`sop`/`eop`), and automatic ACK feedback:

![PCIe DLL Simulation Waveform](docs/waveform.png)
