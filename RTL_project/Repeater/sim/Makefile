RTLDIR = ../src
COMMON = ../../common/src
IPDIR  = ../../common/al_ip
TBDIR  = ./
WAVE   = ./vcd
WORK   = ./work

RTL += $(COMMON)/MAC_DEC.v
RTL += $(COMMON)/FRAME_FIFO.v
RTL += $(COMMON)/sync_2ff.v
RTL += $(COMMON)/vec_sync_2ff.v
RTL += $(COMMON)/crc.v

RTL += $(COMMON)/RMII_TX.v
RTL += $(COMMON)/RMII_RX.v
RTL += $(COMMON)/SNI_TX.v
RTL += $(COMMON)/SNI_RX.v
RTL += $(COMMON)/bin2gray.v
RTL += $(COMMON)/gray2bin.v
RTL += $(COMMON)/m_seq_32.v
RTL += $(COMMON)/mutex.v

IP   = $(IPDIR)/bram32k_sim.v
IP  += $(IPDIR)/bram9k_sim.v

TD_SIM  = $(HOME)/TD/eg_*.v

$(WORK)/tb_rmii_tx.o: tb_rmii_tx.v $(RTL)
	iverilog $^ -o $@

$(WAVE)/tb_rmii_tx.vcd: $(WORK)/tb_rmii_tx.o
	$^

sim_rmii_tx: $(WAVE)/tb_rmii_tx.vcd
	gtkwave $^

$(WORK)/tb_rmii_repeater.o: ./tb_rmii_repeater.v ../src/TOP_RMII_Loopback.v $(RTL) $(IP) $(TD_SIM)
	iverilog $^ -o $@

$(WAVE)/tb_rmii_repeater.vcd: $(WORK)/tb_rmii_repeater.o
	$^

sim_rmii_repeater: $(WAVE)/tb_rmii_repeater.vcd
	gtkwave $^

.PHONY : sim_rmii_tx sim_rmii_repeater
