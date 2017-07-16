/**********************************************************************
    File: sub_ni_rd
    
    Copyright (C) 2013  Alireza Monemi

    This AUTOram is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This AUTOram is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this AUTOram.  If not, see <http://www.gnu.org/licenses/>.
   
    Purpose:
    A DMA based NI for connecting the NoC router to a processor. The NI has 3 
    memory mapped registers:
    
    
       wishbone slave adderess :
    
        [2:0]  
            // ni status register
            0 : STATUS_ADDR 
            // update memory pinter, packet size and send packet read command. If memory pointer and packet size width are smaller than COMB_MEM_PTR_W and COMB_PCK_SIZE_W respectively.
            1 : MEM_PCKSIZ_ADDR       
            //update packet size  
            2: PCK_SIZE_ADDR        
            //update the memory pointer address and send read command. The packet size must be updated before setting this register. use it when memory pointer width is larger than COMB_MEM_PTR_W
            3: MEM_ADDR  
           
        
        
        [3] 
            // rd/wr flag. If ni is in ideal state then 
            0:    RD_CMD  update rd packet register
            1:    WR_CMD  updare wr packet register
        [4+Vw:4]
            // candidate read/write V binarry number. Only write in IDEAL state  
            V_NUM  : rd/wr VC num 
    
    
    
    
        status_reg  
            bit_loc         flag_name
            [14+V : 14+2V-1]rd_vc_not_empty       
            [14 : 14+V-1]   wr_vc_not_empty       
            13              rsv_pck_isr
            12              rd_done_isr
            11              wr_done_isr
            10              rsv_pck_int_en
            9               rd_done_int_en
            8               wr_done_int_en
            7               all_wr_vcs_full
            6               any_rd_vc_has_data
            5               rd_no_pck_err
            4               rd_ovr_size_err
            3               rd_done
            2               wr_done
            1               rd_busy
            0               wr_busy
   
        
        
        RD/WR registers ={pck_size_next,memory_ptr_next}
    
    Info: monemi@fkegraduate.utm.my
*************************************************************************/


`timescale 1ns/1ps





/***************************
        
        sub_ni_rd
        
****************************/



module sub_ni_rd #(

    parameter V    = 4,     // V
    parameter P    = 5,     // router port num
    parameter B    = 4,     // buffer space :flit per VC 
    parameter NX   = 2, // number of node in x axis
    parameter NY   = 2, // number of node in y axis
    parameter Fpay = 32,
    parameter TOPOLOGY =    "MESH",//"MESH","TORUS"
    parameter ROUTE_TYPE   =   "DETERMINISTIC",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter ROUTE_NAME    =   "XY",
    parameter DEBUG_EN =   1,
  
    parameter COMB_MEM_PTR_W=20,
    parameter COMB_PCK_SIZE_W= 12,
    
    //wishbone port parameters
    parameter Dw            =   32,
    parameter S_Aw          =   7,
    parameter M_Aw          =   32,
    parameter TAGw          =   3,
    parameter SELw          =   4
      
    
    )
    (
    
    reset,
    clk,
        
    //noc interface  
    current_x,
    current_y,   
    flit_in,   
    flit_in_wr,   
    credit_out,     
   
    //wishbone slave interface signals
    s_dat_i,
    s_sel_i,
    s_addr_i,  
    s_cti_i,
    s_stb_i,
    s_cyc_i,
    s_we_i,    
    s_dat_o,
    s_ack_o,
    


   
    //wishbone master interface signals
    m_sel_o,
    m_dat_o,
    m_addr_o,
    m_cti_o,
    m_stb_o,
    m_cyc_o,
    m_we_o,
    m_ack_i,    
  
    //intruupt interface
    irq
    
    
); 
 
    function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
    endfunction // log2 
   
    localparam  P_1    =    P-1 ,
                Fw     =    2+V+Fpay, //flit width
                Xw =   log2(NX),
                Yw =   log2(NY),
                Vw =   (V>1) ? log2(V) : 1;  
                   
  
     localparam  
    // ni status register
    STATUS_ADDR       =   3'd0,
    // update memory pinter, packet size and send packet read command. If memory pointer and packet size width are smaller than COMB_MEM_PTR_W and COMB_PCK_SIZE_W respectively.
    MEM_PCKSIZ_ADDR   =   3'd1,  
    //update packet size  
    PCK_SIZE_ADDR     =   3'd2,
    //update the memory pointer address and send read command. The packet size must be updated before setting this register. use it when memory pointer width is larger than COMB_MEM_PTR_W
    MEM_ADDR          =   3'd3,
    //If ni is in ideal state then  update RD/WR packet registers
    RD_CMD            =   1'b0,   
    WR_CMD            =   1'b1;
     
    
    
   
    //status register bit                    
 localparam     NI_RD_BUSY_LOC=         0,
                NI_WR_BUSY_LOC=         1,  
                NI_WR_DONE_LOC=         2,
                NI_RD_DONE_LOC=         3,
                NI_RD_OVR_ERR_LOC=      4,
                NI_RD_NPCK_ERR_LOC=     5,
                NI_HAS_PCK_LOC=         6,
                NI_ALL_VCS_FULL_LOC=    7,
                NI_WR_DONE_INT_EN_LOC=  8,
                NI_RD_DONE_INT_EN_LOC=  9,
                NI_RSV_PCK_INT_EN_LOC=  10,
                NI_WR_DONE_ISR_LOC=     11,
                NI_RD_DONE_ISR_LOC=     12,
                NI_RSV_PCK_ISR_LOC=     13;  
                
                
localparam  CLASS_IN_HDR_WIDTH      =8,
            DEST_IN_HDR_WIDTH       =8,
            X_Y_IN_HDR_WIDTH        =4,
            HDR_ROUTING_INFO_WIDTH  =   CLASS_IN_HDR_WIDTH+DEST_IN_HDR_WIDTH+ 4* X_Y_IN_HDR_WIDTH;
            
localparam  NUMBER_OF_STATUS    =   4,
            IDEAL               =   1,
            RD_VC_CHECK         =   2,// rd stage 1
            WR_ON_RAM           =   4,// rd stage 2
            AUTO_WR             =   8;
                
            
   
    localparam  COUNTER_W       =   M_Aw-2;
    localparam  MEM_PTR_W           =   M_Aw-2;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
  
    
  
    
    
    input reset;
    input clk;
    
    
    // NOC interfaces
    input   [Xw-1   :   0]  current_x;
    input   [Yw-1   :   0]  current_y;
    input   [Fw-1   :   0]  flit_in; 
    input                   flit_in_wr;   
    output reg  [V-1:   0]  credit_out;     
    
    

    //wishbone slave interface signals
    input   [Dw-1       :   0]      s_dat_i;
    input   [SELw-1     :   0]      s_sel_i;
    input   [S_Aw-1     :   0]      s_addr_i;  
    input   [TAGw-1     :   0]      s_cti_i;
    input                           s_stb_i;
    input                           s_cyc_i;
    input                           s_we_i;
    
    output      [Dw-1       :   0]  s_dat_o;
    output  reg                     s_ack_o;
   
    
    
    //wishbone master interface signals
    output  [SELw-1          :   0] m_sel_o;
    output  [Dw-1            :   0] m_dat_o;
    output  [M_Aw-1          :   0] m_addr_o;
    output  [TAGw-1          :   0] m_cti_o;
    output                          m_stb_o;
    output                          m_cyc_o;
    output                          m_we_o;
    input                           m_ack_i;    
    
    //intruupt interface
    output                          irq;
    
  
  
    
   
    
    
    
    
    wire                                m_waitrequest, m_read;
    wire                                s_ack_o_next;
   
    reg                                 m_ack_i_delayed;  
   
   
    reg                                     rsv_pck_isr, rd_done_isr,rsv_pck_int_en, rd_done_int_en;
    reg                                     rsv_pck_isr_next, rd_done_isr_next,rsv_pck_int_en_next, rd_done_int_en_next;
    
        
    reg     [NUMBER_OF_STATUS-1     :   0]  ps,ns;
    reg     [COUNTER_W-1        :   0]  counter,counter_next;
    reg                                     counter_reset,   counter_increase;
    
    // memory mapped registers
    wire    [Fpay-1                 :   0]  status_reg;
   
    
    reg     [MEM_PTR_W-1            :   0]  memory_ptr,memory_ptr_next;
    reg     [COUNTER_W-1            :   0]  pck_size,pck_size_next;
    wire                                    pck_eq_counter;

    
    reg                                     rd_done_next, rd_done;
    reg                                     rd_no_pck_err_next, rd_no_pck_err;
    reg                                     rd_ovr_size_err_next, rd_ovr_size_err;
    reg                                     wr_mem_en, rd_mem_en;
    
    
    
   
    
  
    wire                                    cand_rd_vc_not_empty;
    reg                                     any_vc_has_data;
    
        
    
  
    reg                                     ififo_rd_en; 
    
        
   
    
     
    wire    [Fw-1                   :   0]  ififo_dout;   
    wire    [V-1                    :   0]  ififo_vc_not_empty;
    wire                                    ififo_hdr_flg, ififo_tail_flg;
   
    
   
    reg                                     auto_wr_en,auto_wr_en_delay;
    wire                                    auto_wr_en_next;
    
  
    
  
        wire              rd_busy;

    
    
    
    //wishbone slave register address 
    wire [2:0] wb_general_reg_addr;
    wire       wb_wr_rd_addr;
    wire [Vw-1   :   0] wb_v_addr_binary;
   
    
    reg  [Vw-1  :0] cand_rd_vc_binary;
    wire [V-1  :0]  cand_rd_vc_onehot;
	 wire    [V-1  :0] rd_vc_not_empty;
    
    assign {wb_v_addr_binary, wb_wr_rd_addr, wb_general_reg_addr} = s_addr_i[3+Vw      :0];
    
    
    
    assign  m_sel_o         =   4'b1111;
    assign  m_waitrequest   =   ~m_ack_i_delayed ; //in busrt mode  the ack is regisered inside the ni insted of ram to avoid combinational loop
    assign  m_cyc_o         =   m_we_o | m_read;
    assign  s_ack_o_next    =   s_stb_i & (~s_ack_o);
   // assign  m_cti_o         =   (m_stb_o)   ?   ((last_rw)? 3'b111 :    3'b100) : 3'b000;
    assign  m_cti_o         =   (m_stb_o)   ?      3'b100 : 3'b000;
    
    assign  irq             = (rsv_pck_isr & rsv_pck_int_en) | (rd_done_isr & rd_done_int_en);
        
    
  
    assign  cand_rd_vc_not_empty        =   ififo_vc_not_empty[cand_rd_vc_binary] ;
    
    
    
    assign  m_stb_o         =   wr_mem_en | rd_mem_en;
    assign  m_we_o          =   wr_mem_en;
    assign  m_read          =   rd_mem_en;
    
    assign  m_dat_o         =   {ififo_dout[Fpay-1  :   0]};
    
   
    
    
    wire    [CLASS_IN_HDR_WIDTH-1   :   0]  flit_in_class_hdr;
    wire    [DEST_IN_HDR_WIDTH-1    :   0]  flit_in_destport_hdr;
    wire    [X_Y_IN_HDR_WIDTH-1     :   0]  flit_in_x_src_hdr, flit_in_y_src_hdr, flit_in_x_dst_hdr, flit_in_y_dst_hdr;
    wire    [V-1                    :   0]  flit_in_vc_num;
    wire    [1                      :   0]  flit_in_flg_hdr;


    //extract header flit info
    assign {flit_in_class_hdr,flit_in_destport_hdr, flit_in_x_dst_hdr, flit_in_y_dst_hdr, flit_in_x_src_hdr, flit_in_y_src_hdr}= flit_in [HDR_ROUTING_INFO_WIDTH-1      :0];
    assign flit_in_vc_num = flit_in [Fpay+V-1    :   Fpay];
    assign flit_in_flg_hdr= flit_in [Fw-1    :   Fw-2];    
    assign auto_wr_en_next    =   flit_in_flg_hdr[1] & (flit_in_class_hdr == {CLASS_IN_HDR_WIDTH{1'b1}});    



   


    
    
   
    
    assign ififo_hdr_flg            =   ififo_dout  [Fw-1 ];
    assign ififo_tail_flg           =   ififo_dout  [Fw-2 ];
   
      
    //status register
    assign  rd_busy            =   ps!=IDEAL;
    assign  status_reg          =   {rd_vc_not_empty,/*wr_vc_not_empty*/{V{1'b0}},rsv_pck_isr, rd_done_isr,/*wr_done_isr*/1'b0,rsv_pck_int_en, rd_done_int_en,/*wr_done_int_en*/1'b0,/*all_vcs_full*/1'b0,any_vc_has_data,rd_no_pck_err,rd_ovr_size_err,rd_done,/*wr_done*/1'b0,rd_busy,/*wr_busy*/1'b0};
    assign  s_dat_o             =   status_reg;
   
    reg  [M_Aw-1          :   0] m_addr;
     
     always @ ( posedge clk or posedge reset)begin 
        if(reset)begin 
            m_addr<= {M_Aw{1'b0}};
        end else begin  
            m_addr<= memory_ptr_next+counter_next;
        end
     end
     
     
    
 
    assign  m_addr_o    =   m_addr;
        
    assign  pck_eq_counter = ( counter == pck_size);
        
                                                                       
    
       
    
    
    always@(posedge clk or posedge reset)begin
        if(reset)begin
            ps                  <=  IDEAL;
            memory_ptr          <=  {MEM_PTR_W{1'b0}};
            pck_size            <=  {COUNTER_W{1'b0}};
            counter             <=  {COUNTER_W{1'b0}};
            
            rd_done             <=  1'b0;
            rd_no_pck_err       <=  1'b0;
            rd_ovr_size_err     <=  1'b0;
            any_vc_has_data     <=  1'b0;
            auto_wr_en          <=  1'b0;
            auto_wr_en_delay    <=  1'b0;
            m_ack_i_delayed     <=  1'b0;
            s_ack_o             <=  1'b0;
            rsv_pck_int_en      <=  1'b0;
            rd_done_int_en      <=  1'b0;
            rsv_pck_isr         <=  1'b0;
            rd_done_isr         <=  1'b0;
            
            
        end else begin //if reset
            ps                  <=  ns;
            memory_ptr          <=  memory_ptr_next;
            pck_size            <=  pck_size_next;
            counter             <=  counter_next;
            
            rd_done             <=  rd_done_next;
            rd_no_pck_err       <=  rd_no_pck_err_next;
            rd_ovr_size_err     <=  rd_ovr_size_err_next;
            any_vc_has_data     <=  | ififo_vc_not_empty;
            auto_wr_en          <=  auto_wr_en_next;
            auto_wr_en_delay    <=  auto_wr_en;
            m_ack_i_delayed     <=  m_ack_i;
            s_ack_o             <=  s_ack_o_next;
            rsv_pck_int_en      <=  rsv_pck_int_en_next;
            rd_done_int_en      <=  rd_done_int_en_next;
            rsv_pck_isr         <=  rsv_pck_isr_next;            
            rd_done_isr         <=  rd_done_isr_next;
            
        end//els reset
    end//always
    
    
    // flit counter & candidate read VC
    always@(*)begin
        counter_next        = counter;  
       
        if      (counter_reset)             counter_next    =   {COUNTER_W{1'b0}};
        else if (counter_increase)          counter_next    =   counter +1'b1;
       
     end//always
    
    reg rd_done_trg;
    
    
    
    //update the read\write memory pointer and packet size in flits
     always@(*) begin
        memory_ptr_next     = memory_ptr;
        pck_size_next       = pck_size;
        case(ps)
        IDEAL:   begin
            if(s_stb_i &    s_we_i & (wb_wr_rd_addr == RD_CMD))   begin 
                case (wb_general_reg_addr)
                MEM_PCKSIZ_ADDR: begin 
                    memory_ptr_next = {{(MEM_PTR_W+2-COMB_MEM_PTR_W){1'b0}},s_dat_i[COMB_MEM_PTR_W-1:2]};  
                    pck_size_next   = {{(COMB_MEM_PTR_W-2){1'b0}},s_dat_i[M_Aw-1:COMB_MEM_PTR_W]};                  
                end
                PCK_SIZE_ADDR :begin
                    pck_size_next   = s_dat_i[COUNTER_W-1  :0];   
                end
                MEM_ADDR :begin
                    memory_ptr_next = s_dat_i[MEM_PTR_W+1:2];          
                end
                default:begin 
                    memory_ptr_next     = memory_ptr;
                    pck_size_next       = pck_size;
                end 
                endcase
            end//if  
        end
        AUTO_WR :   begin
            memory_ptr_next = ififo_dout[MEM_PTR_W-1 :0];  
            pck_size_next   =   {COUNTER_W{1'b1}};        
        end
        default : begin
            memory_ptr_next     = memory_ptr;
            pck_size_next       = pck_size;
        end
        endcase
     end
  
  
  
   //update the cand read\write VC
     always@(posedge clk or posedge reset) begin
        if(reset)begin 
              cand_rd_vc_binary<= {Vw{1'b0}};
        end else begin 
             if( s_stb_i &  s_we_i & (wb_general_reg_addr != STATUS_ADDR) & (ps == IDEAL ) ) begin            
                if(wb_wr_rd_addr == RD_CMD)  cand_rd_vc_binary <= wb_v_addr_binary;                   
            end
        end
     end
     
     
    bin_to_one_hot #(
        .BIN_WIDTH(Vw)   
    )
    conv_rd_vc
    (
        .bin_code(cand_rd_vc_binary),
        .one_hot_code(cand_rd_vc_onehot)
    );
     
   
  
  
    
    always@(*) begin
        ns                      = ps;
        counter_reset           = 1'b0;
        counter_increase        = 1'b0;
        ififo_rd_en             = 1'b0;  
        wr_mem_en               = 1'b0;
        credit_out              = {V{1'b0}};
        rd_mem_en               = 1'b0;
        rd_done_next            = rd_done;
        rd_no_pck_err_next  = rd_no_pck_err;
        rd_ovr_size_err_next    = rd_ovr_size_err;     
        rd_done_trg             = 1'b0;
        
        case(ps)
        IDEAL:   begin 
            counter_reset =1;
            if  (auto_wr_en_delay)    begin
                ns                  =   AUTO_WR;
                ififo_rd_en         =   1'b1;
                credit_out          =   cand_rd_vc_onehot;
            end
            if(s_stb_i &    s_we_i )   begin 
                if ((wb_general_reg_addr ==  MEM_PCKSIZ_ADDR) || (wb_general_reg_addr == MEM_ADDR))  begin   
                     if(wb_wr_rd_addr == RD_CMD) begin                    
                            rd_done_next            = 1'b0;
                            rd_ovr_size_err_next    = 1'b0;  
                            rd_no_pck_err_next      = 1'b0;                  
                            ns= RD_VC_CHECK;
                            
                        end// RD_CMD
 
                end//if
            end//if
        end//IDEAL
        

	RD_VC_CHECK: begin
             if(cand_rd_vc_not_empty) begin 
                        //synthesis translate_off
                            //$display ("%t,\t   core (%d,%d) has recived a packet",$time,current_x,current_y);
                        //synthesis translate_on                                                                
                        ns  = WR_ON_RAM;
                        rd_no_pck_err_next  = 1'b0;
                        ififo_rd_en         = 1'b1; 
                        credit_out          =   cand_rd_vc_onehot;
                    end else  begin
                            ns= IDEAL;
                            rd_no_pck_err_next= 1'b1;
                    end//if
        
        
        end // RD_VC_CHECK    

       
            
        WR_ON_RAM:  begin
            rd_no_pck_err_next= 1'b0;
            if(ififo_tail_flg) begin
                if(~m_waitrequest) begin 
                    ns                          =   IDEAL;
                    
                    rd_done_next            =   1'b1;
                    rd_done_trg             =  1'b1;
                    wr_mem_en               =   1'b1;
                 end else  wr_mem_en         =   1'b1;
            end //ififo_tail_flg
            else if(~m_waitrequest) begin 
                if(cand_rd_vc_not_empty ) begin
                    ififo_rd_en             = 1'b1; 
                    credit_out              =   cand_rd_vc_onehot;
                    counter_increase        = 1'b1;
                    if( pck_eq_counter )    rd_ovr_size_err_next    =   1'b1;
                    else                        wr_mem_en   =   1'b1;
                end// cand_rd_vc_not_empty
            end //m_waitrequest
            else    if(cand_rd_vc_not_empty ) wr_mem_en =   1'b1;
        end //WR_ON_RAM
            
        AUTO_WR :   begin                  
            if(cand_rd_vc_not_empty ) begin
                ififo_rd_en             = 1'b1; 
                credit_out              = cand_rd_vc_onehot;
                if(! ififo_hdr_flg)   ns=   WR_ON_RAM;
            end// if(cand_AUTO_vc_not_empty )                
        end//AUTO_WR       
            
        default : ns=IDEAL;
        
        endcase
    end
    
    
    //isr_register handeling
    always @(*) begin
            rsv_pck_int_en_next     = rsv_pck_int_en;
            rd_done_int_en_next     = rd_done_int_en;
            rsv_pck_isr_next            = rsv_pck_isr;          
            rd_done_isr_next            = rd_done_isr;
            
        
        if(any_vc_has_data) rsv_pck_isr_next  = 1'b1;
        if(rd_done_trg  )     rd_done_isr_next  = 1'b1;
       
        
        
        if(s_stb_i &   s_we_i & (wb_general_reg_addr == STATUS_ADDR) ) begin 
            rsv_pck_int_en_next     = s_dat_i[NI_RSV_PCK_INT_EN_LOC];
            rd_done_int_en_next     = s_dat_i[NI_RD_DONE_INT_EN_LOC];
           
    
            if (s_dat_i[NI_RSV_PCK_ISR_LOC]) rsv_pck_isr_next = 1'b0;
            if (s_dat_i[NI_RD_DONE_ISR_LOC]) rd_done_isr_next = 1'b0;
            
        end
    end

// input buffer
    
 flit_buffer #(
    .V(V),
    .B(B),
    .Fpay(Fpay),
    .DEBUG_EN(DEBUG_EN),
    .SSA_EN("NO")
    
 )
 the_ififo
 (
    .din(flit_in),     // Data in
    .vc_num_wr(flit_in_vc_num),//write vertual channel    
    .wr_en(flit_in_wr),   // Write enable
    .vc_num_rd(cand_rd_vc_onehot),//read vertual channel     
    .rd_en(ififo_rd_en),   // Read the next word
    .dout(ififo_dout),    // Data out
    .vc_not_empty(ififo_vc_not_empty),
    .reset(reset),
    .clk(clk),
    .ssa_rd({V{1'b0}})
    
    
 );
  
  assign rd_vc_not_empty = ififo_vc_not_empty;
    
    

    //synthesis translate_off
always @(posedge clk) begin
    if(flit_in_wr && (flit_in_vc_num=={V{1'b0}})) $display ("%d,\t   Error: a packet has been recived by x[%d] , y[%d] with no assigned VC",$time,current_x,current_y);
end


//synthesis translate_on

endmodule










