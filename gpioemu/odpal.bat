iverilog -o gpioemu.vvp gpioemu.v gpioemu_tb.v
vvp gpioemu.vvp
gtkwave.exe gpioemu.vcd