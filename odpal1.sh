makeQemuGpioEmu ./gpioemu/gpioemu.v
qemu-system-riscv32 -machine sykt -bios none --machine dumpdtb=sykom.dtb
dtc -I dtb -O dts -o sykom.dts sykom.dtb
cp ../lab3/sykom.ld .
echo "Teraz pozmieniaj offsety w kodzie c i w sykom.ld"