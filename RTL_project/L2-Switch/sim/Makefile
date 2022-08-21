RTLDIR = ../src
IPDIR  = ../../common/al_ip
TBDIR  = ./
WAVE   = ./vcd
WORK   = ./work

RTL  = $(RTLDIR)/MAC_SWITCH.v
RTL += $(RTLDIR)/MAC_DEC.v
RTL += $(RTLDIR)/sync_2ff.v
RTL += $(RTLDIR)/vec_sync_2ff.v
RTL += $(RTLDIR)/crc.v

RTL += $(RTLDIR)/RMII_TX.v
RTL += $(RTLDIR)/RMII_RX.v
RTL += $(RTLDIR)/SNI_TX.v
RTL += $(RTLDIR)/SNI_RX.v
RTL += $(RTLDIR)/bin2gray.v
RTL += $(RTLDIR)/gray2bin.v
RTL += $(RTLDIR)/m_seq_32.v
RTL += $(RTLDIR)/mutex.v

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
