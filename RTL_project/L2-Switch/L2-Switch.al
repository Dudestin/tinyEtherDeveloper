<?xml version="1.0" encoding="UTF-8"?>
<Project>
    <Project_Created_Time>2022-08-21 12:10:52</Project_Created_Time>
    <TD_Version>4.6.14756</TD_Version>
    <UCode>00111001</UCode>
    <Name>L2-Switch</Name>
    <HardWare>
        <Family>EG4</Family>
        <Device>EG4S20BG256</Device>
    </HardWare>
    <Source_Files>
        <Verilog>
            <File>src/verilog-cam/rtl/cam.v</File>
            <File>src/verilog-cam/rtl/cam_srl.v</File>
            <File>../common/src/bin2gray.v</File>
            <File>../common/src/crc.v</File>
            <File>../common/src/FRAME_FIFO.v</File>
            <File>../common/src/gray2bin.v</File>
            <File>../common/src/RMII_RX.v</File>
            <File>../common/src/RMII_TX.v</File>
            <File>../common/src/RTL_SYNC_FIFO.v</File>
            <File>../common/src/sync_2ff.v</File>
            <File>../common/src/vec_sync_2ff.v</File>
            <File>../common/al_ip/bram9k.v</File>
            <File>../common/al_ip/bram32k.v</File>
            <File>../common/al_ip/HEADER_FIFO.v</File>
            <File>../common/al_ip/pll_clk100M.v</File>
            <File>../common/al_ip/ram_dp_ip.v</File>
            <File>src/TOP_Simple_RMII_L2_SWITCH.v</File>
            <File>../common/src/PACKET_FIFO.v</File>
            <File>src/TOP_L2_SWITCH.v</File>
            <File>src/soc/rtl/picosoc.v</File>
            <File>src/soc/rtl/simpleuart.v</File>
            <File>src/soc/rtl/picorv32.v</File>
            <File>src/soc/rtl/al_ip/sram9k.v</File>
            <File>src/MAC_SWITCH.v</File>
            <File>al_ip/soc_reg_bram.v</File>
            <File>../common/src/LATCH_MAC_DEC.v</File>
        </Verilog>
        <ADC_FILE>constraints/rmii_io.adc</ADC_FILE>
        <SDC_FILE>constraints/rmii_timing.sdc</SDC_FILE>
        <CWC_FILE/>
    </Source_Files>
    <TOP_MODULE>
        <LABEL/>
        <MODULE>TOP_L2_SWITCH</MODULE>
        <CREATEINDEX>user</CREATEINDEX>
    </TOP_MODULE>
    <Property>
        <GateProperty>
            <opt_timing>high</opt_timing>
        </GateProperty>
        <PlaceProperty>
            <opt_timing>high</opt_timing>
        </PlaceProperty>
        <RouteProperty>
            <opt_timing>high</opt_timing>
        </RouteProperty>
        <TimingProperty/>
        <GlobalProperty/>
        <DesignProperty/>
        <RtlProperty/>
        <SimProperty/>
        <BitgenProperty::GeneralOption>
            <s>off</s>
        </BitgenProperty::GeneralOption>
    </Property>
    <Project_Settings>
        <Step_Last_Change>2022-08-31 14:05:40</Step_Last_Change>
        <Current_Step>10</Current_Step>
        <Step_Status>true</Step_Status>
    </Project_Settings>
</Project>
