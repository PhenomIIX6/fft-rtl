# fft-rtl

SystemVerilog FFT project with QuestaSim simulation flow, parameterization capability.

## Project Structure

```text
.
├── LICENSE
├── Makefile
├── README.md
├── rtl
│   ├── common
│   │   ├── dpram.sv
│   │   ├── fifo.sv
│   │   └── pipeline_register.sv
│   ├── control_unit.sv
│   ├── fft.sv
│   ├── memory_controller
│   │   ├── memory_controller.sv
│   │   └── ping_pong.sv
│   ├── radix2
│   │   ├── complex_multiplier.sv
│   │   ├── radix2_core.sv
│   │   ├── radix2_top.sv
│   │   └── round_trunc_scale.sv
│   ├── ram_export_unit.sv
│   ├── ram_init_unit.sv
│   ├── rtl.f
│   └── twiddle_factors
│       ├── rom.sv
│       └── twiddle_factors_rom.sv
├── sim
│   ├── common
│   │   ├── complex_t_package.sv
│   │   ├── fixedpoint_functions.sv
│   │   └── params_package.sv
│   ├── dpi
│   │   ├── dpi.h
│   │   ├── fft.c
│   │   ├── radix2_core.c
│   │   └── twiddle_factors.c
│   ├── fft
│   │   └── fft_tb.sv
│   ├── radix2_core
│   │   ├── complex_multiplier_tb.sv
│   │   └── radix2_core_tb.sv
│   ├── sim.f
│   └── twiddle_factors
│       └── twiddle_factors_rom_tb.sv
├── sw
│   └── twiddle_factors_rom_generate.c
└── top.f
```

## Parameters

The following parameters can be overridden when invoking `make`.

| Parameter           | Default                                | Description |
|---------------------|----------------------------------------|-------------|
| `WIDTH`             | `16`                                   | Total bit width of fixed-point samples. |
| `INTEGER_WIDTH`     | `2`                                    | Number of integer bits in the fixed-point format. |
| `N`                 | `512`                                  | FFT length (should be a power of two). |
| `ROUND`             | `1`                                    | 0 - use truncation after "butterfly", 1 - use rounding after "butterfly" |
| `SATURATION`        | `1`                                    | 0 - use saturation after "butterfly", 1 - do not use saturation after "butterfly" |
| `RADIX_OUT_SCALE`   | `1`                                    | Value of shift after "butterfly" |

## Quick Start

Run the default flow:

```bash
make questa
```

This command will:

1. Compile the DPI-C shared library.
2. Generate the twiddle-factor initialization file.
3. Compile SystemVerilog sources.
4. Run the default testbench.