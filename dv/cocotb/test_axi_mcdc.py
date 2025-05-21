# Copyright AccurateRTL contributors.
# Licensed under the MIT License, see LICENSE for details.
# SPDX-License-Identifier: MIT

import logging
import random
import math
import itertools
import cocotb
import os

import cocotb_test.simulator
import pytest

from cocotb.triggers import FallingEdge, RisingEdge, Timer, Event
from cocotb.regression import TestFactory
from cocotb.clock import Clock
from cocotbext.axi import AxiBus, AxiMaster, AxiRam

async def cycle_reset(dut):
    dut.axis_arstn.setimmediatevalue(0)
    dut.axim_arstn.setimmediatevalue(0)
    
    for i in range(10):
        await RisingEdge(dut.axis_aclk)
    dut.axis_arstn.setimmediatevalue(1)
    
    await RisingEdge(dut.axim_aclk)
    dut.axim_arstn.setimmediatevalue(1)


def cycle_pause():
    return itertools.cycle([1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0])

def random_pause():
    l = [1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0]
    random.shuffle(l)
    return itertools.cycle(l)    
    
def set_idle_generator(axi_master, axi_ram, generator=None):
    if generator:
      axi_master.write_if.aw_channel.set_pause_generator(generator())
      axi_master.write_if.w_channel.set_pause_generator(generator())
      axi_master.read_if.ar_channel.set_pause_generator(generator())
      axi_ram.write_if.b_channel.set_pause_generator(generator())
      axi_ram.read_if.r_channel.set_pause_generator(generator())
      


def set_backpressure_generator(axi_master, axi_ram, generator=None):
    if generator:
      axi_master.write_if.b_channel.set_pause_generator(generator())
      axi_master.read_if.r_channel.set_pause_generator(generator())

      axi_ram.write_if.aw_channel.set_pause_generator(generator())
      axi_ram.write_if.w_channel.set_pause_generator(generator())
      axi_ram.read_if.ar_channel.set_pause_generator(generator())
      
      
async def mcdc_test(dut, mclk=10, sclk=20, idle_gen=None, bpres_gen=None):
    """Try accessing the design!"""
    dut.axis_arstn.setimmediatevalue(0)
    dut.axim_arstn.setimmediatevalue(0)
    
    cocotb.start_soon(Clock(dut.axis_aclk, mclk, units="ns").start())
    cocotb.start_soon(Clock(dut.axim_aclk, sclk, units="ns").start())

    await cycle_reset(dut)

    axi_ram     =  AxiRam(AxiBus.from_prefix(dut, "axim"), dut.axim_aclk, dut.axim_arstn, reset_active_level=False, size=2**18)
    axi_master  = AxiMaster(AxiBus.from_prefix(dut,"axis"), dut.axis_aclk, dut.axis_arstn, False)
   
    set_idle_generator(axi_master, axi_ram, idle_gen)  
    set_backpressure_generator(axi_master, axi_ram, bpres_gen) 

    await Timer(100, units="ns")
 
#    for i in range(256) 
    wr_data = bytes(range(256))
    await axi_master.write(0, wr_data)
    
    rd_data = await axi_master.read(0x0000, 256) 
    
    for i in range(256):
      assert rd_data.data[i] == wr_data[i]
               
    for i in range(8):
     await axi_master.write_dword(i*4, i)
    
    for i in range(8):
      rd = await axi_master.read_dword(i*4)
      print("RD DATA: %x" % rd)
      assert rd == i
      
    
    await Timer(100, units="ns")
    print("End of timer 2")


if cocotb.SIM_NAME:
# Проверяем работоспособность всех каналов при различных длинах транзакций
    for test in [mcdc_test]:
        factory = TestFactory(test)
        factory.add_option("mclk", [10, 20])
        factory.add_option("sclk", [10, 20])
        factory.add_option("idle_gen", [random_pause, None, cycle_pause])
        factory.add_option("bpres_gen", [None, cycle_pause, random_pause])
        factory.generate_tests()
