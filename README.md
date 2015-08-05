# BBN QDSP Firmware

Firmware to run a superconducting qubit measurement transceiver on the
[Innovative Integration X6-1000M
card](http://www.innovative-dsp.com/products.php?product=X6-1000M).

## Dependencies

* [verilog-axis](https://github.com/alexforencich/verilog-axis) - for AXI stream components
* [VHDL-Components](https://github.com/BBN-Q/VHDL-Components) - for complex multiplier; polyphase SSB and cross-clock synchronizer

## ISE Project Setup

Modify the ``scripts/create_project.tcl`` to set the project name and directory
and FPGA part parameters.  Then from the tcl console in ISE run:

```tcl
cd /path/to/scripts/folder
source create_project.tcl
create_project
regenerate_ip
```

## Software Driver

The firmware works with a C-API driver [libx6](https://github.com/BBN-Q/libx6).

## License

The BBN written modules are licensed under the Mozilla Public License.  Files in the ii_mods directory are modified from original Innovative Integration code and carry their own license.
