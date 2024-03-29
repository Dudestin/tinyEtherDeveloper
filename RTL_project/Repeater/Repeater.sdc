# This file is generated by Anlogic Timing Wizard. 22 08 2022

#Created Clock
create_clock -name phy0_ref_clk -period 20 -waveform {0 10} [get_ports {PHY0_REF_CLK}] -add
create_clock -name phy1_ref_clk -period 20 -waveform {0 10} [get_ports {PHY1_REF_CLK}]

#Set Input/Output Delay
set_input_delay -clock phy0_ref_clk -min 2 [get_ports {PHY0_RXD0} {PHY0_RXD1} {PHY0_CRS}]
set_input_delay -clock phy1_ref_clk -min 2 [get_ports {PHY1_RXD0} {PHY1_RXD1} {PHY1_CRS}]
set_output_delay -clock phy0_ref_clk -min 2 [get_ports {PHY0_TXD0} {PHY0_TXD1} {PHY0_TXEN}]
set_output_delay -clock phy0_ref_clk -max 16 [get_ports {PHY0_TXD0} {PHY0_TXD1} {PHY0_TXEN}]
set_output_delay -clock phy1_ref_clk -min 2 [get_ports {PHY1_TXD0} {PHY1_TXD1} {PHY1_TXEN}]
set_output_delay -clock phy1_ref_clk -max 16 [get_ports {PHY1_TXD0} {PHY1_TXD1} {PHY1_TXEN}]

#Set Clock Groups
set_clock_groups -exclusive -group [get_clocks {phy0_ref_clk}] -group [get_clocks {phy1_ref_clk}]

