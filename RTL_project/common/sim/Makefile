RTLDIR = ../src
IPDIR  = ../al_ip
TBDIR  = ./
WAVE   = ./vcd
WORK   = ./work

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

IP   = $(IPDIR)/bram32k_sim.v
IP  += $(IPDIR)/bram9k_sim.v

TD_SIM  = $(HOME)/TD/eg_*.v

$(WORK)/tb_rmii_tx.o: tb_rmii_tx.v $(RTL)
	iverilog $^ -o $@

$(WAVE)/tb_rmii_tx.vcd: $(WORK)/tb_rmii_tx.o
	$^

sim_rmii_tx: $(WAVE)/tb_rmii_tx.vcd
	gtkwave $^

$(WORK)/tb_mutex.o: tb_mutex.v $(RTL) $(IP)
	iverilog $^ -o $@

$(WAVE)/tb_mutex.vcd: $(WORK)/tb_mutex.o
	$^

sim_mutex: $(WAVE)/tb_mutex.vcd
	gtkwave $^

$(WORK)/tb_FRAME_FIFO.o: ../src/FRAME_FIFO.v tb_FRAME_FIFO.v $(RTL) $(IP) $(TD_SIM)
	iverilog $^ -o $@

$(WAVE)/tb_frame_fifo.vcd: $(WORK)/tb_FRAME_FIFO.o
	$^

sim_frame_fifo: $(WAVE)/tb_frame_fifo.vcd
	gtkwave $^

.PHONY : sim_mutex sim_rmii_tx sim_frame_fifo 
