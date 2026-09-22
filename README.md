# FPGA-Based Graphics Accelerator

A hardware graphics accelerator implemented in **SystemVerilog** and integrated into a **RISC-V SoC** for FPGA deployment.

The project implements hardware-accelerated drawing operations, with a focus on efficient circle generation using **Bresenham's circle algorithm**. The design replaces computationally expensive operations such as square roots with incremental integer arithmetic and uses the symmetry of a circle to reduce the amount of computation required.

The accelerator is controlled by a RISC-V processor through a memory-mapped register interface and writes generated pixels to a simulated frame buffer.

---

## Project Overview

The goal of this project was to move graphics processing from software running on a RISC-V processor into dedicated FPGA hardware.

A conventional software implementation requires the processor to calculate the pixels that make up a graphical primitive. Instead, this project implements the drawing algorithm directly in RTL, allowing the FPGA to perform the calculations independently once the operation has been configured.

The overall system can be viewed as:

```text
                    RISC-V Processor
                           │
                           │ Memory-Mapped
                           │ Register Interface
                           ▼
              ┌──────────────────────────┐
              │   Graphics Accelerator   │
              │                          │
              │  Control / Status Logic  │
              │           │              │
              │           ▼              │
              │    Circle Generator      │
              │           │              │
              │           ▼              │
              │      Pixel Output        │
              └────────────┬─────────────┘
                           │
                           ▼
                     Frame Buffer
                           │
                           ▼
                        Display
