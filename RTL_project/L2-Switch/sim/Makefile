COMDIR = ../../common/src
RTLDIR = ../src
IPDIR  = ../../common/al_ip
TBDIR  = ./
WAVE   = ./vcd
WORK   = ./work

RTL  = ../src/NEW_MAC_SWITCH.v
RTL += $(COMDIR)/MAC_DEC.v
RTL += $(COMDIR)/sync_2ff.v
RTL += $(COMDIR)/vec_sync_2ff.v
RTL += $(COMDIR)/crc.v

RTL += $(COMDIR)/RMII_TX.v
RTL += $(COMDIR)/RMII_RX.v
RTL += $(COMDIR)/SNI_TX.v
RTL += $(COMDIR)/SNI_RX.v
RTL += $(COMDIR)/bin2gray.v
RTL += $(COMDIR)/gray2bin.v
RTL += $(COMDIR)/m_seq_32.v
RTL += $(COMDIR)/mutex.v

RTL += $(RTLDIR)/verilog-cam/rtl/cam.v
RTL += $(RTLDIR)/verilog-cam/rtl/cam_srl.v
RTL += $(RTLDIR)/verilog-cam/rtl/cam_bram.v
RTL += $(RTLDIR)/verilog-cam/rtl/priority_encoder.v

IP   = $(IPDIR)/bram32k_sim.v
IP  += $(IPDIR)/bram9k_sim.v

TD_SIM  = $(HOME)/TD/eg_*.v

$(WORK)/tb_switch.o: tb_MAC_SWITCH.v $(RTL)
	iverilog $^ -o $@

$(WAVE)/tb_switch.vcd: $(WORK)/tb_switch.o
	$^

sim_switch: $(WAVE)/tb_switch.vcd
	gtkwave $^


.PHONY : sim_switch 
