**⚡ FMCW Radar Control and Data Acquisition on FPGA**

This project implements the complete digital backend of an FMCW radar system using VHDL and Xilinx MicroBlaze, integrating ramp control, ADC sampling, FIR decimation, and high-speed USB 2.0 streaming to a PC.

**🔧 System Architecture**

The design separates slow-control and high-speed signal processing into two domains:

**MicroBlaze Subsystem:**
Handles low-speed configuration of on-board ICs (ADF4158 PLL, amplifier) through GPIO, SPI, and UART interfaces.
Generates control signals such as ramp start, ramp configured, and sampling done flags.

**FPGA Logic Subsystem:**
Dedicated to high-speed ADC data acquisition and USB 2.0 data transfer to the host PC using an FT2232H in synchronous FIFO mode. Main modules of fpga design are:

microblaze_wrapper.vhd — Soft CPU with AXI peripherals for SPI, GPIO, and UART configuration.

config.vhd — Receives configuration packets from the host over USB; stores and forwards parameters to MicroBlaze.

control.vhd — FSM managing ADC enable/disable, PA control, and USB write timing synchronized to ADF4158 MUXOUT.

adc.vhd — Interleaved dual-phase ADC capture with FIR decimation by 20.

usb_sync.vhd — Implements the FT2232H synchronous FIFO interface for reliable bidirectional USB communication.

clk_wiz_0 — MMCM generating separate 40 MHz (logic) and 100 MHz (MicroBlaze) domains.

**🧩 Simulation Results**


**Configuration Path:** Sequential byte reception over USB (config.vhd) forming correct 64-bit packets.

<img width="3247" height="1763" alt="Image" src="https://github.com/user-attachments/assets/ecc14d3f-d771-4332-979e-05445e62164b" />


**Sampling & Control:** Proper sequencing of ADC sampling during ramp (MUXOUT = 1) and data upload during gap.

<img width="3247" height="1763" alt="Image" src="https://github.com/user-attachments/assets/6f54ff55-025c-480d-ae85-85af0a34b7c0" />

<img width="3247" height="1763" alt="Image" src="https://github.com/user-attachments/assets/60c4a199-748d-4475-af2e-11a2b4144a63" />


**ADC Behavior:** FIR-filtered and decimated dual-channel outputs synchronized with valid pulses.

<img width="3247" height="1763" alt="Image" src="https://github.com/user-attachments/assets/dc2684fb-aff9-48e1-9ecc-e25510b73626" />

<img width="3247" height="1763" alt="Image" src="https://github.com/user-attachments/assets/addd7541-d3f9-4c5a-bd35-dd87aca477c6" />


**🚀 Key Features**

Dual-clock architecture: 40 MHz sampling / 100 MHz MicroBlaze control

USB 2.0 synchronous FIFO communication to PC

FIR low-pass filtering and decimation integrated in the ADC chain

Real-time ramp/gap control via ADF4158 MUXOUT

Software reset and handshake signals between VHDL logic and MicroBlaze firmware

Extendable for BRAM-based data exchange or AXI-DMA streaming

**🧠 Next Steps**

Implement shared dual-port BRAM for configuration data exchange with MicroBlaze

Integrate FFT/range-Doppler preprocessing

Add Python GUI for runtime control and data visualization
