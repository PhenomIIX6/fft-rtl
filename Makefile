.PHONY: questa c_compile clean

# Params
WIDTH ?= 16
INTEGER_WIDTH ?= 2
N ?= 512
# TODO: Complete all params
# TODO: Override params in questasim
# TODO: Help target

# Twiddle factors generate
TW_C_SRC = $(shell find ./sw/ -type f -name "*.c")
TW_ROM_INITFILE = ./twiddle_factors.bin
TW_C_OUT = ./tw_file_gen.out
TW_CFLAGS ?= -DWIDTH=$(WIDTH) -DINTEGER_WIDTH=$(INTEGER_WIDTH) -DN=$(N) -DFILENAME=\"$(TW_ROM_INITFILE)\" -lm

# DPI
DPI_C_FILES = $(shell find ./sim/dpi/ -type f -name "*.c")
DPI_INCLUDE_FILES ?= $(HOME)/soft/questa/questasim/include
DPI_CFLAGS ?= -shared -fPIC -lm -I $(DPI_INCLUDE_FILES)

# Testbench target
TB ?= fft_tb
SIM_TOP = work.$(TB)

$(TW_C_OUT): $(TW_C_SRC)
	$(CC) -o $@ $^ $(TW_CFLAGS) 

$(TW_ROM_INITFILE): $(TW_C_OUT)
	./$(TW_C_OUT)

libdpi.so: $(DPI_C_FILES)
	$(CC) -o $@ $^ $(DPI_CFLAGS) 

c_compile: libdpi.so

prepare: $(TW_ROM_INITFILE)

questa: c_compile prepare
	vlog -work work -sv -f top.f
	vsim -64 -voptargs=+acc -sv_lib libdpi $(SIM_TOP)

clean:
	rm -rf *.so
	rm -rf work transcript vsim.wlf vsim_stacktrace.vstf
	rm -rf *.out *.bin