module  ss_fifo_sync    (
                 wr_rdy ,       // buffer write ready
                 rd_rdy ,       // buffer read ready
                 rd_do  ,       // read data out

                 wr_di  ,       // write data in
                 wr_en  ,       // write enable
                 rd_en  ,       // read enable
                 clk    ,       // clock
                 reset  );      // sync reset ( h active )

        parameter        Bw_d   = 8     ;
        parameter        Bw_a   = 10    ;
        parameter        Depth  = ( 1 << Bw_a ) ;
        parameter        Thrs_wr= Depth/4*3     ;       // for write ready
        parameter        Thrs_rd= Depth/4*1     ;       // for read ready

        input   [Bw_d-1:00]      wr_di  ;       // write data in
        input                    wr_en  ;       // write enable
        input                    rd_en  ;       // read enable
        input                    clk    ;       // clock
        input                    reset  ;       // sync reset ( h active )

        output                   wr_rdy ;       // buffer write ready
        output                   rd_rdy ;       // buffer read ready
        output  [Bw_d-1:00]      rd_do  ;       // read data out

// wires & regs
        reg     [Bw_a:00]        wr_ad  ;       // wr address
        reg     [Bw_a:00]        rd_ad  ;       // rd address
        wire    [Bw_a:00]        df_ad  ;       // address difference

        reg     [Bw_d-1:00]      m_ary  [0:Depth-1] ;       // memory array
        reg     [Bw_d-1:00]      rd_do  ;       // data output reg

// write pointer
        always  @( posedge clk ) begin
                if      ( reset )       wr_ad   <= {(Bw_a+1){1'b0}} ;
                else if ( wr_en )       wr_ad   <= wr_ad + 1'b1 ;
        end

// read pointer
        always  @( posedge clk ) begin
                if      ( reset )       rd_ad   <= {(Bw_a+1){1'h0}} ;
                else if ( rd_en )       rd_ad   <= rd_ad + 1'b1 ;
        end

// occupancy
        assign           df_ad  = wr_ad - rd_ad ;
        assign           wr_rdy = ~df_ad[Bw_a] & ( df_ad[Bw_a-1:00] <= Thrs_wr ) ;
        assign           rd_rdy = ~df_ad[Bw_a] & ( df_ad[Bw_a-1:00] >= Thrs_rd ) ;

// memory wr
        always  @( posedge clk ) begin
                if      ( wr_en )       m_ary[wr_ad[Bw_a-1:00]] <= wr_di ;
        end

// memory rd
        always  @( posedge clk ) begin
                rd_do   <= m_ary[rd_ad[Bw_a-1:00]] ;
        end

endmodule