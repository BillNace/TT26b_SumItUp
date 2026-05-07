# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_single_transaction(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Turn go_l off
    dut.uio_in.value = 1

    dut._log.info("Add 8 + 7 (expected sum is F)")

    # Set the input values you want to test
    dut.ui_in.value = 8
    dut.uio_in.value = 0 # go_l is bit 0

    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 1 # go_l is now unasserted
    dut.ui_in.value = 7
    
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == 15 # Hex F
    assert dut.uio_out.value[1] == 1

