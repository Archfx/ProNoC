module soc_jtag #(
    	parameter	ram_Aw=14 ,
	parameter	ram_RAM_TAG_STRING="00" ,
	parameter	aeMB_AEMB_MUL= 1 ,
	parameter	aeMB_AEMB_BSF= 1 ,
	parameter	gpo_PORT_WIDTH=   1 ,
	parameter	jtag_intfc_WR_RAMw=8 ,
	parameter	ni_NY=3 ,
	parameter	ni_NX=3 ,
	parameter	ni_V=2 ,
	parameter	ni_B= 4 ,
	parameter	ni_ROUTE_NAME="XY"      ,
	parameter	ni_TOPOLOGY=    "MESH"
)(
	aeMB_sys_ena_i, 
	aeMB_sys_int_i, 
	clk_source_clk_in, 
	clk_source_reset_in, 
	gpo_port_o, 
	int_ctrl_int_o, 
	jtag_intfc_irq, 
	jtag_intfc_reset_all_o, 
	jtag_intfc_reset_cpus_o, 
	ni_credit_in, 
	ni_credit_out, 
	ni_current_x, 
	ni_current_y, 
	ni_flit_in, 
	ni_flit_in_wr, 
	ni_flit_out, 
	ni_flit_out_wr
);
  
  	function integer log2;
  		input integer number; begin	
          	log2=0;	
          	while(2**log2<number) begin	
        		  	log2=log2+1;	
         		end	
        		end	
     	endfunction // log2 
  
//Wishbone slave base address based on instance name
 	localparam 	ram_BASE_ADDR	=	32'h00000000;
 	localparam 	ram_END_ADDR	=	32'h00003fff;
 	localparam 	gpo_BASE_ADDR	=	32'h24400000;
 	localparam 	gpo_END_ADDR	=	32'h24400007;
 	localparam 	int_ctrl_BASE_ADDR	=	32'h27800000;
 	localparam 	int_ctrl_END_ADDR	=	32'h27800007;
 	localparam 	jtag_intfc_BASE_ADDR	=	32'h24000000;
 	localparam 	jtag_intfc_END_ADDR	=	32'h240003ff;
 	localparam 	ni_BASE_ADDR	=	32'h2e000000;
 	localparam 	ni_END_ADDR	=	32'h2e000007;
 
 
//Wishbone slave base address based on module name. 
 	localparam 	Altera_ram0_BASE_ADDR	=	32'h00000000;
 	localparam 	Altera_ram0_END_ADDR	=	32'h00003fff;
 	localparam 	gpo0_BASE_ADDR	=	32'h24400000;
 	localparam 	gpo0_END_ADDR	=	32'h24400007;
 	localparam 	int_ctrl0_BASE_ADDR	=	32'h27800000;
 	localparam 	int_ctrl0_END_ADDR	=	32'h27800007;
 	localparam 	jtag_intfc0_BASE_ADDR	=	32'h24000000;
 	localparam 	jtag_intfc0_END_ADDR	=	32'h240003ff;
 	localparam 	ni0_BASE_ADDR	=	32'h2e000000;
 	localparam 	ni0_END_ADDR	=	32'h2e000007;
 
 	localparam	ram_FPGA_FAMILY="ALTERA";
	localparam	ram_TAGw=3;
	localparam	ram_Dw=32;
	localparam	ram_SELw=4;

 	localparam	aeMB_AEMB_XWB= 7;
	localparam	aeMB_AEMB_IDX= 6;
	localparam	aeMB_AEMB_IWB= 32;
	localparam	aeMB_AEMB_ICH= 11;
	localparam	aeMB_AEMB_DWB= 32;

 
 	localparam	gpo_Dw=    32;
	localparam	gpo_Aw=    2;
	localparam	gpo_TAGw=    3;
	localparam	gpo_SELw=    4;

 	localparam	int_ctrl_INT_NUM=1;
	localparam	int_ctrl_Dw=    32;
	localparam	int_ctrl_Aw= 3;
	localparam	int_ctrl_SELw= 4    ;

 	localparam	jtag_intfc_NI_BASE_ADDR=ni0_BASE_ADDR;
	localparam	jtag_intfc_JTAG_BASE_ADDR=jtag_intfc0_BASE_ADDR;
	localparam	jtag_intfc_WR_RAM_TAG="J_WR";
	localparam	jtag_intfc_RD_RAM_TAG="J_RD";
	localparam	jtag_intfc_Dw=32;
	localparam	jtag_intfc_S_Aw=jtag_intfc_WR_RAMw+1;
	localparam	jtag_intfc_M_Aw=32;
	localparam	jtag_intfc_TAGw=3;
	localparam	jtag_intfc_SELw=4;

 	localparam	ni_Dw=32;
	localparam	ni_DEBUG_EN=   1;
	localparam	ni_TAGw=   3;
	localparam	ni_M_Aw=32;
	localparam	ni_Fpay= 32;
	localparam	ni_SELw=   4    ;
	localparam	ni_ROUTE_TYPE=   (ni_ROUTE_NAME == "XY" || ni_ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
			            (ni_ROUTE_NAME == "DUATO" || ni_ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE" ;
	localparam	ni_P= 5;
	localparam	ni_S_Aw=   3;
	localparam	ni_Fw=2 + ni_V + ni_Fpay;
	localparam	ni_Xw=log2( ni_NX );
	localparam	ni_Yw=log2( ni_NY );

 	localparam	bus_S=5;
	localparam	bus_M=	4;
	localparam	bus_Aw=	32;
	localparam	bus_TAGw=	3    ;
	localparam	bus_SELw=	4;
	localparam	bus_Dw=	32;

 	input			aeMB_sys_ena_i;
 	input			aeMB_sys_int_i;

 	input			clk_source_clk_in;
 	input			clk_source_reset_in;

 	output	 [ gpo_PORT_WIDTH-1     :   0    ] gpo_port_o;

 	output			int_ctrl_int_o;

 	output			jtag_intfc_irq;
 	output			jtag_intfc_reset_all_o;
 	output			jtag_intfc_reset_cpus_o;

 	input	 [ ni_V-1    :   0    ] ni_credit_in;
 	output	 [ ni_V-1:   0    ] ni_credit_out;
 	input	 [ ni_Xw-1   :   0    ] ni_current_x;
 	input	 [ ni_Yw-1   :   0    ] ni_current_y;
 	input	 [ ni_Fw-1   :   0    ] ni_flit_in;
 	input			ni_flit_in_wr;
 	output	 [ ni_Fw-1   :   0    ] ni_flit_out;
 	output			ni_flit_out_wr;

 	wire			 ram_plug_clk_0_clk_i;
 	wire			 ram_plug_reset_0_reset_i;
 	wire			 ram_plug_wb_slave_0_ack_o;
 	wire	[ ram_Aw-1       :   0 ] ram_plug_wb_slave_0_adr_i;
 	wire			 ram_plug_wb_slave_0_cyc_i;
 	wire	[ ram_Dw-1       :   0 ] ram_plug_wb_slave_0_dat_i;
 	wire	[ ram_Dw-1       :   0 ] ram_plug_wb_slave_0_dat_o;
 	wire			 ram_plug_wb_slave_0_err_o;
 	wire			 ram_plug_wb_slave_0_rty_o;
 	wire	[ ram_SELw-1     :   0 ] ram_plug_wb_slave_0_sel_i;
 	wire			 ram_plug_wb_slave_0_stb_i;
 	wire	[ ram_TAGw-1     :   0 ] ram_plug_wb_slave_0_tag_i;
 	wire			 ram_plug_wb_slave_0_we_i;

 	wire			 aeMB_plug_clk_0_clk_i;
 	wire			 aeMB_plug_wb_master_1_ack_i;
 	wire	[ 31:0 ] aeMB_plug_wb_master_1_adr_o;
 	wire			 aeMB_plug_wb_master_1_cyc_o;
 	wire	[ 31:0 ] aeMB_plug_wb_master_1_dat_i;
 	wire	[ 31:0 ] aeMB_plug_wb_master_1_dat_o;
 	wire			 aeMB_plug_wb_master_1_err_i;
 	wire			 aeMB_plug_wb_master_1_rty_i;
 	wire	[ 3:0 ] aeMB_plug_wb_master_1_sel_o;
 	wire			 aeMB_plug_wb_master_1_stb_o;
 	wire	[ 2:0 ] aeMB_plug_wb_master_1_tag_o;
 	wire			 aeMB_plug_wb_master_1_we_o;
 	wire			 aeMB_plug_wb_master_0_ack_i;
 	wire	[ 31:0 ] aeMB_plug_wb_master_0_adr_o;
 	wire			 aeMB_plug_wb_master_0_cyc_o;
 	wire	[ 31:0 ] aeMB_plug_wb_master_0_dat_i;
 	wire	[ 31:0 ] aeMB_plug_wb_master_0_dat_o;
 	wire			 aeMB_plug_wb_master_0_err_i;
 	wire			 aeMB_plug_wb_master_0_rty_i;
 	wire	[ 3:0 ] aeMB_plug_wb_master_0_sel_o;
 	wire			 aeMB_plug_wb_master_0_stb_o;
 	wire	[ 2:0 ] aeMB_plug_wb_master_0_tag_o;
 	wire			 aeMB_plug_wb_master_0_we_o;
 	wire			 aeMB_plug_reset_0_reset_i;

 	wire			 clk_source_socket_clk_0_clk_o;
 	wire			 clk_source_socket_reset_0_reset_o;

 	wire			 gpo_plug_clk_0_clk_i;
 	wire			 gpo_plug_reset_0_reset_i;
 	wire			 gpo_plug_wb_slave_0_ack_o;
 	wire	[ gpo_Aw-1       :   0 ] gpo_plug_wb_slave_0_adr_i;
 	wire			 gpo_plug_wb_slave_0_cyc_i;
 	wire	[ gpo_Dw-1       :   0 ] gpo_plug_wb_slave_0_dat_i;
 	wire	[ gpo_Dw-1       :   0 ] gpo_plug_wb_slave_0_dat_o;
 	wire			 gpo_plug_wb_slave_0_err_o;
 	wire			 gpo_plug_wb_slave_0_rty_o;
 	wire	[ gpo_SELw-1     :   0 ] gpo_plug_wb_slave_0_sel_i;
 	wire			 gpo_plug_wb_slave_0_stb_i;
 	wire	[ gpo_TAGw-1     :   0 ] gpo_plug_wb_slave_0_tag_i;
 	wire			 gpo_plug_wb_slave_0_we_i;

 	wire			 int_ctrl_plug_clk_0_clk_i;
 	wire	[ int_ctrl_INT_NUM-1  :   0 ] int_ctrl_socket_interrupt_peripheral_array_int_i;
 	wire			 int_ctrl_socket_interrupt_peripheral_0_int_i;
 	wire			 int_ctrl_plug_reset_0_reset_i;
 	wire			 int_ctrl_plug_wb_slave_0_ack_o;
 	wire	[ int_ctrl_Aw-1       :   0 ] int_ctrl_plug_wb_slave_0_adr_i;
 	wire	[ int_ctrl_Dw-1       :   0 ] int_ctrl_plug_wb_slave_0_dat_i;
 	wire	[ int_ctrl_Dw-1       :   0 ] int_ctrl_plug_wb_slave_0_dat_o;
 	wire			 int_ctrl_plug_wb_slave_0_err_o;
 	wire			 int_ctrl_plug_wb_slave_0_rty_o;
 	wire	[ int_ctrl_SELw-1     :   0 ] int_ctrl_plug_wb_slave_0_sel_i;
 	wire			 int_ctrl_plug_wb_slave_0_stb_i;
 	wire			 int_ctrl_plug_wb_slave_0_we_i;

 	wire			 jtag_intfc_plug_clk_0_clk_i;
 	wire			 jtag_intfc_plug_wb_master_0_ack_i;
 	wire	[ jtag_intfc_M_Aw-1          :   0 ] jtag_intfc_plug_wb_master_0_adr_o;
 	wire			 jtag_intfc_plug_wb_master_0_cyc_o;
 	wire	[ jtag_intfc_Dw-1           :  0 ] jtag_intfc_plug_wb_master_0_dat_i;
 	wire	[ jtag_intfc_Dw-1            :   0 ] jtag_intfc_plug_wb_master_0_dat_o;
 	wire			 jtag_intfc_plug_wb_master_0_err_i;
 	wire			 jtag_intfc_plug_wb_master_0_rty_i;
 	wire	[ jtag_intfc_SELw-1          :   0 ] jtag_intfc_plug_wb_master_0_sel_o;
 	wire			 jtag_intfc_plug_wb_master_0_stb_o;
 	wire	[ jtag_intfc_TAGw-1          :   0 ] jtag_intfc_plug_wb_master_0_tag_o;
 	wire			 jtag_intfc_plug_wb_master_0_we_o;
 	wire			 jtag_intfc_plug_reset_0_reset_i;
 	wire			 jtag_intfc_plug_wb_slave_0_ack_o;
 	wire	[ jtag_intfc_S_Aw-1     :   0 ] jtag_intfc_plug_wb_slave_0_adr_i;
 	wire			 jtag_intfc_plug_wb_slave_0_cyc_i;
 	wire	[ jtag_intfc_Dw-1       :   0 ] jtag_intfc_plug_wb_slave_0_dat_i;
 	wire	[ jtag_intfc_Dw-1       :   0 ] jtag_intfc_plug_wb_slave_0_dat_o;
 	wire			 jtag_intfc_plug_wb_slave_0_err_o;
 	wire			 jtag_intfc_plug_wb_slave_0_rty_o;
 	wire	[ jtag_intfc_SELw-1     :   0 ] jtag_intfc_plug_wb_slave_0_sel_i;
 	wire			 jtag_intfc_plug_wb_slave_0_stb_i;
 	wire	[ jtag_intfc_TAGw-1     :   0 ] jtag_intfc_plug_wb_slave_0_tag_i;
 	wire			 jtag_intfc_plug_wb_slave_0_we_i;

 	wire			 ni_plug_clk_0_clk_i;
 	wire			 ni_plug_interrupt_peripheral_0_int_o;
 	wire			 ni_plug_wb_master_0_ack_i;
 	wire	[ ni_M_Aw-1          :   0 ] ni_plug_wb_master_0_adr_o;
 	wire			 ni_plug_wb_master_0_cyc_o;
 	wire	[ ni_Dw-1           :  0 ] ni_plug_wb_master_0_dat_i;
 	wire	[ ni_Dw-1            :   0 ] ni_plug_wb_master_0_dat_o;
 	wire			 ni_plug_wb_master_0_err_i;
 	wire			 ni_plug_wb_master_0_rty_i;
 	wire	[ ni_SELw-1          :   0 ] ni_plug_wb_master_0_sel_o;
 	wire			 ni_plug_wb_master_0_stb_o;
 	wire	[ ni_TAGw-1          :   0 ] ni_plug_wb_master_0_tag_o;
 	wire			 ni_plug_wb_master_0_we_o;
 	wire			 ni_plug_reset_0_reset_i;
 	wire			 ni_plug_wb_slave_0_ack_o;
 	wire	[ ni_S_Aw-1     :   0 ] ni_plug_wb_slave_0_adr_i;
 	wire			 ni_plug_wb_slave_0_cyc_i;
 	wire	[ ni_Dw-1       :   0 ] ni_plug_wb_slave_0_dat_i;
 	wire	[ ni_Dw-1       :   0 ] ni_plug_wb_slave_0_dat_o;
 	wire			 ni_plug_wb_slave_0_err_o;
 	wire			 ni_plug_wb_slave_0_rty_o;
 	wire	[ ni_SELw-1     :   0 ] ni_plug_wb_slave_0_sel_i;
 	wire			 ni_plug_wb_slave_0_stb_i;
 	wire	[ ni_TAGw-1     :   0 ] ni_plug_wb_slave_0_tag_i;
 	wire			 ni_plug_wb_slave_0_we_i;

 	wire			 bus_plug_clk_0_clk_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_ack_o;
 	wire			 bus_socket_wb_master_3_ack_o;
 	wire			 bus_socket_wb_master_2_ack_o;
 	wire			 bus_socket_wb_master_1_ack_o;
 	wire			 bus_socket_wb_master_0_ack_o;
 	wire	[ (bus_Aw*bus_M)-1      :   0 ] bus_socket_wb_master_array_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_3_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_2_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_1_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_0_adr_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_cyc_i;
 	wire			 bus_socket_wb_master_3_cyc_i;
 	wire			 bus_socket_wb_master_2_cyc_i;
 	wire			 bus_socket_wb_master_1_cyc_i;
 	wire			 bus_socket_wb_master_0_cyc_i;
 	wire	[ (bus_Dw*bus_M)-1      :   0 ] bus_socket_wb_master_array_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_3_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_2_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_1_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_0_dat_i;
 	wire	[ (bus_Dw*bus_M)-1      :   0 ] bus_socket_wb_master_array_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_3_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_2_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_1_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_0_dat_o;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_err_o;
 	wire			 bus_socket_wb_master_3_err_o;
 	wire			 bus_socket_wb_master_2_err_o;
 	wire			 bus_socket_wb_master_1_err_o;
 	wire			 bus_socket_wb_master_0_err_o;
 	wire	[ bus_Aw-1       :   0 ] bus_socket_wb_addr_map_0_grant_addr;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_rty_o;
 	wire			 bus_socket_wb_master_3_rty_o;
 	wire			 bus_socket_wb_master_2_rty_o;
 	wire			 bus_socket_wb_master_1_rty_o;
 	wire			 bus_socket_wb_master_0_rty_o;
 	wire	[ (bus_SELw*bus_M)-1    :   0 ] bus_socket_wb_master_array_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_3_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_2_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_1_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_0_sel_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_stb_i;
 	wire			 bus_socket_wb_master_3_stb_i;
 	wire			 bus_socket_wb_master_2_stb_i;
 	wire			 bus_socket_wb_master_1_stb_i;
 	wire			 bus_socket_wb_master_0_stb_i;
 	wire	[ (bus_TAGw*bus_M)-1    :   0 ] bus_socket_wb_master_array_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_3_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_2_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_1_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_0_tag_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_we_i;
 	wire			 bus_socket_wb_master_3_we_i;
 	wire			 bus_socket_wb_master_2_we_i;
 	wire			 bus_socket_wb_master_1_we_i;
 	wire			 bus_socket_wb_master_0_we_i;
 	wire			 bus_plug_reset_0_reset_i;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_ack_i;
 	wire			 bus_socket_wb_slave_4_ack_i;
 	wire			 bus_socket_wb_slave_3_ack_i;
 	wire			 bus_socket_wb_slave_2_ack_i;
 	wire			 bus_socket_wb_slave_1_ack_i;
 	wire			 bus_socket_wb_slave_0_ack_i;
 	wire	[ (bus_Aw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_4_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_3_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_2_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_1_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_0_adr_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_cyc_o;
 	wire			 bus_socket_wb_slave_4_cyc_o;
 	wire			 bus_socket_wb_slave_3_cyc_o;
 	wire			 bus_socket_wb_slave_2_cyc_o;
 	wire			 bus_socket_wb_slave_1_cyc_o;
 	wire			 bus_socket_wb_slave_0_cyc_o;
 	wire	[ (bus_Dw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_4_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_3_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_2_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_1_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_0_dat_i;
 	wire	[ (bus_Dw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_4_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_3_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_2_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_1_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_0_dat_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_err_i;
 	wire			 bus_socket_wb_slave_4_err_i;
 	wire			 bus_socket_wb_slave_3_err_i;
 	wire			 bus_socket_wb_slave_2_err_i;
 	wire			 bus_socket_wb_slave_1_err_i;
 	wire			 bus_socket_wb_slave_0_err_i;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_rty_i;
 	wire			 bus_socket_wb_slave_4_rty_i;
 	wire			 bus_socket_wb_slave_3_rty_i;
 	wire			 bus_socket_wb_slave_2_rty_i;
 	wire			 bus_socket_wb_slave_1_rty_i;
 	wire			 bus_socket_wb_slave_0_rty_i;
 	wire	[ (bus_SELw*bus_S)-1    :   0 ] bus_socket_wb_slave_array_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_4_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_3_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_2_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_1_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_0_sel_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_addr_map_0_sel_one_hot;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_stb_o;
 	wire			 bus_socket_wb_slave_4_stb_o;
 	wire			 bus_socket_wb_slave_3_stb_o;
 	wire			 bus_socket_wb_slave_2_stb_o;
 	wire			 bus_socket_wb_slave_1_stb_o;
 	wire			 bus_socket_wb_slave_0_stb_o;
 	wire	[ (bus_TAGw*bus_S)-1    :   0 ] bus_socket_wb_slave_array_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_4_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_3_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_2_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_1_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_0_tag_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_we_o;
 	wire			 bus_socket_wb_slave_4_we_o;
 	wire			 bus_socket_wb_slave_3_we_o;
 	wire			 bus_socket_wb_slave_2_we_o;
 	wire			 bus_socket_wb_slave_1_we_o;
 	wire			 bus_socket_wb_slave_0_we_o;

 prog_ram_single_port #(
 		.Aw(ram_Aw),
		.FPGA_FAMILY(ram_FPGA_FAMILY),
		.RAM_TAG_STRING(ram_RAM_TAG_STRING),
		.TAGw(ram_TAGw),
		.Dw(ram_Dw),
		.SELw(ram_SELw)
	)  ram 	(
		.clk(ram_plug_clk_0_clk_i),
		.reset(ram_plug_reset_0_reset_i),
		.sa_ack_o(ram_plug_wb_slave_0_ack_o),
		.sa_addr_i(ram_plug_wb_slave_0_adr_i),
		.sa_cyc_i(ram_plug_wb_slave_0_cyc_i),
		.sa_dat_i(ram_plug_wb_slave_0_dat_i),
		.sa_dat_o(ram_plug_wb_slave_0_dat_o),
		.sa_err_o(ram_plug_wb_slave_0_err_o),
		.sa_rty_o(ram_plug_wb_slave_0_rty_o),
		.sa_sel_i(ram_plug_wb_slave_0_sel_i),
		.sa_stb_i(ram_plug_wb_slave_0_stb_i),
		.sa_tag_i(ram_plug_wb_slave_0_tag_i),
		.sa_we_i(ram_plug_wb_slave_0_we_i)
	);
 aeMB_top #(
 		.AEMB_XWB(aeMB_AEMB_XWB),
		.AEMB_IDX(aeMB_AEMB_IDX),
		.AEMB_MUL(aeMB_AEMB_MUL),
		.AEMB_IWB(aeMB_AEMB_IWB),
		.AEMB_BSF(aeMB_AEMB_BSF),
		.AEMB_ICH(aeMB_AEMB_ICH),
		.AEMB_DWB(aeMB_AEMB_DWB)
	)  aeMB 	(
		.clk(aeMB_plug_clk_0_clk_i),
		.dwb_ack_i(aeMB_plug_wb_master_1_ack_i),
		.dwb_adr_o(aeMB_plug_wb_master_1_adr_o),
		.dwb_cyc_o(aeMB_plug_wb_master_1_cyc_o),
		.dwb_dat_i(aeMB_plug_wb_master_1_dat_i),
		.dwb_dat_o(aeMB_plug_wb_master_1_dat_o),
		.dwb_err_i(aeMB_plug_wb_master_1_err_i),
		.dwb_rty_i(aeMB_plug_wb_master_1_rty_i),
		.dwb_sel_o(aeMB_plug_wb_master_1_sel_o),
		.dwb_stb_o(aeMB_plug_wb_master_1_stb_o),
		.dwb_tag_o(aeMB_plug_wb_master_1_tag_o),
		.dwb_wre_o(aeMB_plug_wb_master_1_we_o),
		.iwb_ack_i(aeMB_plug_wb_master_0_ack_i),
		.iwb_adr_o(aeMB_plug_wb_master_0_adr_o),
		.iwb_cyc_o(aeMB_plug_wb_master_0_cyc_o),
		.iwb_dat_i(aeMB_plug_wb_master_0_dat_i),
		.iwb_dat_o(aeMB_plug_wb_master_0_dat_o),
		.iwb_err_i(aeMB_plug_wb_master_0_err_i),
		.iwb_rty_i(aeMB_plug_wb_master_0_rty_i),
		.iwb_sel_o(aeMB_plug_wb_master_0_sel_o),
		.iwb_stb_o(aeMB_plug_wb_master_0_stb_o),
		.iwb_tag_o(aeMB_plug_wb_master_0_tag_o),
		.iwb_wre_o(aeMB_plug_wb_master_0_we_o),
		.reset(aeMB_plug_reset_0_reset_i),
		.sys_ena_i(aeMB_sys_ena_i),
		.sys_int_i(aeMB_sys_int_i)
	);
 clk_source  clk_source 	(
		.clk_in(clk_source_clk_in),
		.clk_out(clk_source_socket_clk_0_clk_o),
		.reset_in(clk_source_reset_in),
		.reset_out(clk_source_socket_reset_0_reset_o)
	);
 gpo #(
 		.PORT_WIDTH(gpo_PORT_WIDTH),
		.Dw(gpo_Dw),
		.Aw(gpo_Aw),
		.TAGw(gpo_TAGw),
		.SELw(gpo_SELw)
	)  gpo 	(
		.clk(gpo_plug_clk_0_clk_i),
		.port_o(gpo_port_o),
		.reset(gpo_plug_reset_0_reset_i),
		.sa_ack_o(gpo_plug_wb_slave_0_ack_o),
		.sa_addr_i(gpo_plug_wb_slave_0_adr_i),
		.sa_cyc_i(gpo_plug_wb_slave_0_cyc_i),
		.sa_dat_i(gpo_plug_wb_slave_0_dat_i),
		.sa_dat_o(gpo_plug_wb_slave_0_dat_o),
		.sa_err_o(gpo_plug_wb_slave_0_err_o),
		.sa_rty_o(gpo_plug_wb_slave_0_rty_o),
		.sa_sel_i(gpo_plug_wb_slave_0_sel_i),
		.sa_stb_i(gpo_plug_wb_slave_0_stb_i),
		.sa_tag_i(gpo_plug_wb_slave_0_tag_i),
		.sa_we_i(gpo_plug_wb_slave_0_we_i)
	);
 int_ctrl #(
 		.INT_NUM(int_ctrl_INT_NUM),
		.Dw(int_ctrl_Dw),
		.Aw(int_ctrl_Aw),
		.SELw(int_ctrl_SELw)
	)  int_ctrl 	(
		.clk(int_ctrl_plug_clk_0_clk_i),
		.int_i(int_ctrl_socket_interrupt_peripheral_array_int_i),
		.int_o(int_ctrl_int_o),
		.reset(int_ctrl_plug_reset_0_reset_i),
		.sa_ack_o(int_ctrl_plug_wb_slave_0_ack_o),
		.sa_addr_i(int_ctrl_plug_wb_slave_0_adr_i),
		.sa_dat_i(int_ctrl_plug_wb_slave_0_dat_i),
		.sa_dat_o(int_ctrl_plug_wb_slave_0_dat_o),
		.sa_err_o(int_ctrl_plug_wb_slave_0_err_o),
		.sa_rty_o(int_ctrl_plug_wb_slave_0_rty_o),
		.sa_sel_i(int_ctrl_plug_wb_slave_0_sel_i),
		.sa_stb_i(int_ctrl_plug_wb_slave_0_stb_i),
		.sa_we_i(int_ctrl_plug_wb_slave_0_we_i)
	);
 jtag_intfc #(
 		.NI_BASE_ADDR(jtag_intfc_NI_BASE_ADDR),
		.JTAG_BASE_ADDR(jtag_intfc_JTAG_BASE_ADDR),
		.WR_RAM_TAG(jtag_intfc_WR_RAM_TAG),
		.RD_RAM_TAG(jtag_intfc_RD_RAM_TAG),
		.WR_RAMw(jtag_intfc_WR_RAMw),
		.Dw(jtag_intfc_Dw),
		.S_Aw(jtag_intfc_S_Aw),
		.M_Aw(jtag_intfc_M_Aw),
		.TAGw(jtag_intfc_TAGw),
		.SELw(jtag_intfc_SELw)
	)  jtag_intfc 	(
		.clk(jtag_intfc_plug_clk_0_clk_i),
		.irq(jtag_intfc_irq),
		.m_ack_i(jtag_intfc_plug_wb_master_0_ack_i),
		.m_addr_o(jtag_intfc_plug_wb_master_0_adr_o),
		.m_cyc_o(jtag_intfc_plug_wb_master_0_cyc_o),
		.m_dat_i(jtag_intfc_plug_wb_master_0_dat_i),
		.m_dat_o(jtag_intfc_plug_wb_master_0_dat_o),
		.m_err_i(jtag_intfc_plug_wb_master_0_err_i),
		.m_rty_i(jtag_intfc_plug_wb_master_0_rty_i),
		.m_sel_o(jtag_intfc_plug_wb_master_0_sel_o),
		.m_stb_o(jtag_intfc_plug_wb_master_0_stb_o),
		.m_tag_o(jtag_intfc_plug_wb_master_0_tag_o),
		.m_we_o(jtag_intfc_plug_wb_master_0_we_o),
		.reset(jtag_intfc_plug_reset_0_reset_i),
		.reset_all_o(jtag_intfc_reset_all_o),
		.reset_cpus_o(jtag_intfc_reset_cpus_o),
		.s_ack_o(jtag_intfc_plug_wb_slave_0_ack_o),
		.s_addr_i(jtag_intfc_plug_wb_slave_0_adr_i),
		.s_cyc_i(jtag_intfc_plug_wb_slave_0_cyc_i),
		.s_dat_i(jtag_intfc_plug_wb_slave_0_dat_i),
		.s_dat_o(jtag_intfc_plug_wb_slave_0_dat_o),
		.s_err_o(jtag_intfc_plug_wb_slave_0_err_o),
		.s_rty_o(jtag_intfc_plug_wb_slave_0_rty_o),
		.s_sel_i(jtag_intfc_plug_wb_slave_0_sel_i),
		.s_stb_i(jtag_intfc_plug_wb_slave_0_stb_i),
		.s_tag_i(jtag_intfc_plug_wb_slave_0_tag_i),
		.s_we_i(jtag_intfc_plug_wb_slave_0_we_i)
	);
 ni #(
 		.NY(ni_NY),
		.NX(ni_NX),
		.V(ni_V),
		.B(ni_B),
		.Dw(ni_Dw),
		.DEBUG_EN(ni_DEBUG_EN),
		.TAGw(ni_TAGw),
		.M_Aw(ni_M_Aw),
		.ROUTE_NAME(ni_ROUTE_NAME),
		.Fpay(ni_Fpay),
		.SELw(ni_SELw),
		.ROUTE_TYPE(ni_ROUTE_TYPE),
		.P(ni_P),
		.S_Aw(ni_S_Aw),
		.TOPOLOGY(ni_TOPOLOGY)
	)  ni 	(
		.clk(ni_plug_clk_0_clk_i),
		.credit_in(ni_credit_in),
		.credit_out(ni_credit_out),
		.current_x(ni_current_x),
		.current_y(ni_current_y),
		.flit_in(ni_flit_in),
		.flit_in_wr(ni_flit_in_wr),
		.flit_out(ni_flit_out),
		.flit_out_wr(ni_flit_out_wr),
		.irq(ni_plug_interrupt_peripheral_0_int_o),
		.m_ack_i(ni_plug_wb_master_0_ack_i),
		.m_addr_o(ni_plug_wb_master_0_adr_o),
		.m_cyc_o(ni_plug_wb_master_0_cyc_o),
		.m_dat_i(ni_plug_wb_master_0_dat_i),
		.m_dat_o(ni_plug_wb_master_0_dat_o),
		.m_err_i(ni_plug_wb_master_0_err_i),
		.m_rty_i(ni_plug_wb_master_0_rty_i),
		.m_sel_o(ni_plug_wb_master_0_sel_o),
		.m_stb_o(ni_plug_wb_master_0_stb_o),
		.m_tag_o(ni_plug_wb_master_0_tag_o),
		.m_we_o(ni_plug_wb_master_0_we_o),
		.reset(ni_plug_reset_0_reset_i),
		.s_ack_o(ni_plug_wb_slave_0_ack_o),
		.s_addr_i(ni_plug_wb_slave_0_adr_i),
		.s_cyc_i(ni_plug_wb_slave_0_cyc_i),
		.s_dat_i(ni_plug_wb_slave_0_dat_i),
		.s_dat_o(ni_plug_wb_slave_0_dat_o),
		.s_err_o(ni_plug_wb_slave_0_err_o),
		.s_rty_o(ni_plug_wb_slave_0_rty_o),
		.s_sel_i(ni_plug_wb_slave_0_sel_i),
		.s_stb_i(ni_plug_wb_slave_0_stb_i),
		.s_tag_i(ni_plug_wb_slave_0_tag_i),
		.s_we_i(ni_plug_wb_slave_0_we_i)
	);
 wishbone_bus #(
 		.S(bus_S),
		.M(bus_M),
		.Aw(bus_Aw),
		.TAGw(bus_TAGw),
		.SELw(bus_SELw),
		.Dw(bus_Dw)
	)  bus 	(
		.clk(bus_plug_clk_0_clk_i),
		.m_ack_o_all(bus_socket_wb_master_array_ack_o),
		.m_adr_i_all(bus_socket_wb_master_array_adr_i),
		.m_cyc_i_all(bus_socket_wb_master_array_cyc_i),
		.m_dat_i_all(bus_socket_wb_master_array_dat_i),
		.m_dat_o_all(bus_socket_wb_master_array_dat_o),
		.m_err_o_all(bus_socket_wb_master_array_err_o),
		.m_grant_addr(bus_socket_wb_addr_map_0_grant_addr),
		.m_rty_o_all(bus_socket_wb_master_array_rty_o),
		.m_sel_i_all(bus_socket_wb_master_array_sel_i),
		.m_stb_i_all(bus_socket_wb_master_array_stb_i),
		.m_tag_i_all(bus_socket_wb_master_array_tag_i),
		.m_we_i_all(bus_socket_wb_master_array_we_i),
		.reset(bus_plug_reset_0_reset_i),
		.s_ack_i_all(bus_socket_wb_slave_array_ack_i),
		.s_adr_o_all(bus_socket_wb_slave_array_adr_o),
		.s_cyc_o_all(bus_socket_wb_slave_array_cyc_o),
		.s_dat_i_all(bus_socket_wb_slave_array_dat_i),
		.s_dat_o_all(bus_socket_wb_slave_array_dat_o),
		.s_err_i_all(bus_socket_wb_slave_array_err_i),
		.s_rty_i_all(bus_socket_wb_slave_array_rty_i),
		.s_sel_o_all(bus_socket_wb_slave_array_sel_o),
		.s_sel_one_hot(bus_socket_wb_addr_map_0_sel_one_hot),
		.s_stb_o_all(bus_socket_wb_slave_array_stb_o),
		.s_tag_o_all(bus_socket_wb_slave_array_tag_o),
		.s_we_o_all(bus_socket_wb_slave_array_we_o)
	);
 
 	assign  ram_plug_clk_0_clk_i = clk_source_socket_clk_0_clk_o;
 	assign  ram_plug_reset_0_reset_i = clk_source_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_3_ack_i  = ram_plug_wb_slave_0_ack_o;
 	assign  ram_plug_wb_slave_0_adr_i = bus_socket_wb_slave_3_adr_o;
 	assign  ram_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_3_cyc_o;
 	assign  ram_plug_wb_slave_0_dat_i = bus_socket_wb_slave_3_dat_o;
 	assign  bus_socket_wb_slave_3_dat_i  = ram_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_3_err_i  = ram_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_3_rty_i  = ram_plug_wb_slave_0_rty_o;
 	assign  ram_plug_wb_slave_0_sel_i = bus_socket_wb_slave_3_sel_o;
 	assign  ram_plug_wb_slave_0_stb_i = bus_socket_wb_slave_3_stb_o;
 	assign  ram_plug_wb_slave_0_tag_i = bus_socket_wb_slave_3_tag_o;
 	assign  ram_plug_wb_slave_0_we_i = bus_socket_wb_slave_3_we_o;

 
 	assign  aeMB_plug_clk_0_clk_i = clk_source_socket_clk_0_clk_o;
 	assign  aeMB_plug_wb_master_1_ack_i = bus_socket_wb_master_1_ack_o;
 	assign  bus_socket_wb_master_1_adr_i  = aeMB_plug_wb_master_1_adr_o;
 	assign  bus_socket_wb_master_1_cyc_i  = aeMB_plug_wb_master_1_cyc_o;
 	assign  aeMB_plug_wb_master_1_dat_i = bus_socket_wb_master_1_dat_o;
 	assign  bus_socket_wb_master_1_dat_i  = aeMB_plug_wb_master_1_dat_o;
 	assign  aeMB_plug_wb_master_1_err_i = bus_socket_wb_master_1_err_o;
 	assign  aeMB_plug_wb_master_1_rty_i = bus_socket_wb_master_1_rty_o;
 	assign  bus_socket_wb_master_1_sel_i  = aeMB_plug_wb_master_1_sel_o;
 	assign  bus_socket_wb_master_1_stb_i  = aeMB_plug_wb_master_1_stb_o;
 	assign  bus_socket_wb_master_1_tag_i  = aeMB_plug_wb_master_1_tag_o;
 	assign  bus_socket_wb_master_1_we_i  = aeMB_plug_wb_master_1_we_o;
 	assign  aeMB_plug_wb_master_0_ack_i = bus_socket_wb_master_0_ack_o;
 	assign  bus_socket_wb_master_0_adr_i  = aeMB_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_0_cyc_i  = aeMB_plug_wb_master_0_cyc_o;
 	assign  aeMB_plug_wb_master_0_dat_i = bus_socket_wb_master_0_dat_o;
 	assign  bus_socket_wb_master_0_dat_i  = aeMB_plug_wb_master_0_dat_o;
 	assign  aeMB_plug_wb_master_0_err_i = bus_socket_wb_master_0_err_o;
 	assign  aeMB_plug_wb_master_0_rty_i = bus_socket_wb_master_0_rty_o;
 	assign  bus_socket_wb_master_0_sel_i  = aeMB_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_0_stb_i  = aeMB_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_0_tag_i  = aeMB_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_0_we_i  = aeMB_plug_wb_master_0_we_o;
 	assign  aeMB_plug_reset_0_reset_i = clk_source_socket_reset_0_reset_o;

 

 
 	assign  gpo_plug_clk_0_clk_i = clk_source_socket_clk_0_clk_o;
 	assign  gpo_plug_reset_0_reset_i = clk_source_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_1_ack_i  = gpo_plug_wb_slave_0_ack_o;
 	assign  gpo_plug_wb_slave_0_adr_i = bus_socket_wb_slave_1_adr_o;
 	assign  gpo_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_1_cyc_o;
 	assign  gpo_plug_wb_slave_0_dat_i = bus_socket_wb_slave_1_dat_o;
 	assign  bus_socket_wb_slave_1_dat_i  = gpo_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_1_err_i  = gpo_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_1_rty_i  = gpo_plug_wb_slave_0_rty_o;
 	assign  gpo_plug_wb_slave_0_sel_i = bus_socket_wb_slave_1_sel_o;
 	assign  gpo_plug_wb_slave_0_stb_i = bus_socket_wb_slave_1_stb_o;
 	assign  gpo_plug_wb_slave_0_tag_i = bus_socket_wb_slave_1_tag_o;
 	assign  gpo_plug_wb_slave_0_we_i = bus_socket_wb_slave_1_we_o;

 
 	assign  int_ctrl_plug_clk_0_clk_i = clk_source_socket_clk_0_clk_o;
 	assign  int_ctrl_plug_reset_0_reset_i = clk_source_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_4_ack_i  = int_ctrl_plug_wb_slave_0_ack_o;
 	assign  int_ctrl_plug_wb_slave_0_adr_i = bus_socket_wb_slave_4_adr_o;
 	assign  int_ctrl_plug_wb_slave_0_dat_i = bus_socket_wb_slave_4_dat_o;
 	assign  bus_socket_wb_slave_4_dat_i  = int_ctrl_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_4_err_i  = int_ctrl_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_4_rty_i  = int_ctrl_plug_wb_slave_0_rty_o;
 	assign  int_ctrl_plug_wb_slave_0_sel_i = bus_socket_wb_slave_4_sel_o;
 	assign  int_ctrl_plug_wb_slave_0_stb_i = bus_socket_wb_slave_4_stb_o;
 	assign  int_ctrl_plug_wb_slave_0_we_i = bus_socket_wb_slave_4_we_o;

 
 	assign  jtag_intfc_plug_clk_0_clk_i = clk_source_socket_clk_0_clk_o;
 	assign  jtag_intfc_plug_wb_master_0_ack_i = bus_socket_wb_master_2_ack_o;
 	assign  bus_socket_wb_master_2_adr_i  = jtag_intfc_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_2_cyc_i  = jtag_intfc_plug_wb_master_0_cyc_o;
 	assign  jtag_intfc_plug_wb_master_0_dat_i = bus_socket_wb_master_2_dat_o;
 	assign  bus_socket_wb_master_2_dat_i  = jtag_intfc_plug_wb_master_0_dat_o;
 	assign  jtag_intfc_plug_wb_master_0_err_i = bus_socket_wb_master_2_err_o;
 	assign  jtag_intfc_plug_wb_master_0_rty_i = bus_socket_wb_master_2_rty_o;
 	assign  bus_socket_wb_master_2_sel_i  = jtag_intfc_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_2_stb_i  = jtag_intfc_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_2_tag_i  = jtag_intfc_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_2_we_i  = jtag_intfc_plug_wb_master_0_we_o;
 	assign  jtag_intfc_plug_reset_0_reset_i = clk_source_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_0_ack_i  = jtag_intfc_plug_wb_slave_0_ack_o;
 	assign  jtag_intfc_plug_wb_slave_0_adr_i = bus_socket_wb_slave_0_adr_o;
 	assign  jtag_intfc_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_0_cyc_o;
 	assign  jtag_intfc_plug_wb_slave_0_dat_i = bus_socket_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_dat_i  = jtag_intfc_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_err_i  = jtag_intfc_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_0_rty_i  = jtag_intfc_plug_wb_slave_0_rty_o;
 	assign  jtag_intfc_plug_wb_slave_0_sel_i = bus_socket_wb_slave_0_sel_o;
 	assign  jtag_intfc_plug_wb_slave_0_stb_i = bus_socket_wb_slave_0_stb_o;
 	assign  jtag_intfc_plug_wb_slave_0_tag_i = bus_socket_wb_slave_0_tag_o;
 	assign  jtag_intfc_plug_wb_slave_0_we_i = bus_socket_wb_slave_0_we_o;

 
 	assign  ni_plug_clk_0_clk_i = clk_source_socket_clk_0_clk_o;
 	assign  int_ctrl_socket_interrupt_peripheral_0_int_i  = ni_plug_interrupt_peripheral_0_int_o;
 	assign  ni_plug_wb_master_0_ack_i = bus_socket_wb_master_3_ack_o;
 	assign  bus_socket_wb_master_3_adr_i  = ni_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_3_cyc_i  = ni_plug_wb_master_0_cyc_o;
 	assign  ni_plug_wb_master_0_dat_i = bus_socket_wb_master_3_dat_o;
 	assign  bus_socket_wb_master_3_dat_i  = ni_plug_wb_master_0_dat_o;
 	assign  ni_plug_wb_master_0_err_i = bus_socket_wb_master_3_err_o;
 	assign  ni_plug_wb_master_0_rty_i = bus_socket_wb_master_3_rty_o;
 	assign  bus_socket_wb_master_3_sel_i  = ni_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_3_stb_i  = ni_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_3_tag_i  = ni_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_3_we_i  = ni_plug_wb_master_0_we_o;
 	assign  ni_plug_reset_0_reset_i = clk_source_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_2_ack_i  = ni_plug_wb_slave_0_ack_o;
 	assign  ni_plug_wb_slave_0_adr_i = bus_socket_wb_slave_2_adr_o;
 	assign  ni_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_2_cyc_o;
 	assign  ni_plug_wb_slave_0_dat_i = bus_socket_wb_slave_2_dat_o;
 	assign  bus_socket_wb_slave_2_dat_i  = ni_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_2_err_i  = ni_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_2_rty_i  = ni_plug_wb_slave_0_rty_o;
 	assign  ni_plug_wb_slave_0_sel_i = bus_socket_wb_slave_2_sel_o;
 	assign  ni_plug_wb_slave_0_stb_i = bus_socket_wb_slave_2_stb_o;
 	assign  ni_plug_wb_slave_0_tag_i = bus_socket_wb_slave_2_tag_o;
 	assign  ni_plug_wb_slave_0_we_i = bus_socket_wb_slave_2_we_o;

 
 	assign  bus_plug_clk_0_clk_i = clk_source_socket_clk_0_clk_o;
 	assign  bus_plug_reset_0_reset_i = clk_source_socket_reset_0_reset_o;

 	assign int_ctrl_socket_interrupt_peripheral_array_int_i =int_ctrl_socket_interrupt_peripheral_0_int_i;

 	assign {bus_socket_wb_master_3_ack_o ,bus_socket_wb_master_2_ack_o ,bus_socket_wb_master_1_ack_o ,bus_socket_wb_master_0_ack_o} =bus_socket_wb_master_array_ack_o;
 	assign bus_socket_wb_master_array_adr_i ={bus_socket_wb_master_3_adr_i ,bus_socket_wb_master_2_adr_i ,bus_socket_wb_master_1_adr_i ,bus_socket_wb_master_0_adr_i};
 	assign bus_socket_wb_master_array_cyc_i ={bus_socket_wb_master_3_cyc_i ,bus_socket_wb_master_2_cyc_i ,bus_socket_wb_master_1_cyc_i ,bus_socket_wb_master_0_cyc_i};
 	assign bus_socket_wb_master_array_dat_i ={bus_socket_wb_master_3_dat_i ,bus_socket_wb_master_2_dat_i ,bus_socket_wb_master_1_dat_i ,bus_socket_wb_master_0_dat_i};
 	assign {bus_socket_wb_master_3_dat_o ,bus_socket_wb_master_2_dat_o ,bus_socket_wb_master_1_dat_o ,bus_socket_wb_master_0_dat_o} =bus_socket_wb_master_array_dat_o;
 	assign {bus_socket_wb_master_3_err_o ,bus_socket_wb_master_2_err_o ,bus_socket_wb_master_1_err_o ,bus_socket_wb_master_0_err_o} =bus_socket_wb_master_array_err_o;
 	assign {bus_socket_wb_master_3_rty_o ,bus_socket_wb_master_2_rty_o ,bus_socket_wb_master_1_rty_o ,bus_socket_wb_master_0_rty_o} =bus_socket_wb_master_array_rty_o;
 	assign bus_socket_wb_master_array_sel_i ={bus_socket_wb_master_3_sel_i ,bus_socket_wb_master_2_sel_i ,bus_socket_wb_master_1_sel_i ,bus_socket_wb_master_0_sel_i};
 	assign bus_socket_wb_master_array_stb_i ={bus_socket_wb_master_3_stb_i ,bus_socket_wb_master_2_stb_i ,bus_socket_wb_master_1_stb_i ,bus_socket_wb_master_0_stb_i};
 	assign bus_socket_wb_master_array_tag_i ={bus_socket_wb_master_3_tag_i ,bus_socket_wb_master_2_tag_i ,bus_socket_wb_master_1_tag_i ,bus_socket_wb_master_0_tag_i};
 	assign bus_socket_wb_master_array_we_i ={bus_socket_wb_master_3_we_i ,bus_socket_wb_master_2_we_i ,bus_socket_wb_master_1_we_i ,bus_socket_wb_master_0_we_i};
 	assign bus_socket_wb_slave_array_ack_i ={bus_socket_wb_slave_4_ack_i ,bus_socket_wb_slave_3_ack_i ,bus_socket_wb_slave_2_ack_i ,bus_socket_wb_slave_1_ack_i ,bus_socket_wb_slave_0_ack_i};
 	assign {bus_socket_wb_slave_4_adr_o ,bus_socket_wb_slave_3_adr_o ,bus_socket_wb_slave_2_adr_o ,bus_socket_wb_slave_1_adr_o ,bus_socket_wb_slave_0_adr_o} =bus_socket_wb_slave_array_adr_o;
 	assign {bus_socket_wb_slave_4_cyc_o ,bus_socket_wb_slave_3_cyc_o ,bus_socket_wb_slave_2_cyc_o ,bus_socket_wb_slave_1_cyc_o ,bus_socket_wb_slave_0_cyc_o} =bus_socket_wb_slave_array_cyc_o;
 	assign bus_socket_wb_slave_array_dat_i ={bus_socket_wb_slave_4_dat_i ,bus_socket_wb_slave_3_dat_i ,bus_socket_wb_slave_2_dat_i ,bus_socket_wb_slave_1_dat_i ,bus_socket_wb_slave_0_dat_i};
 	assign {bus_socket_wb_slave_4_dat_o ,bus_socket_wb_slave_3_dat_o ,bus_socket_wb_slave_2_dat_o ,bus_socket_wb_slave_1_dat_o ,bus_socket_wb_slave_0_dat_o} =bus_socket_wb_slave_array_dat_o;
 	assign bus_socket_wb_slave_array_err_i ={bus_socket_wb_slave_4_err_i ,bus_socket_wb_slave_3_err_i ,bus_socket_wb_slave_2_err_i ,bus_socket_wb_slave_1_err_i ,bus_socket_wb_slave_0_err_i};
 	assign bus_socket_wb_slave_array_rty_i ={bus_socket_wb_slave_4_rty_i ,bus_socket_wb_slave_3_rty_i ,bus_socket_wb_slave_2_rty_i ,bus_socket_wb_slave_1_rty_i ,bus_socket_wb_slave_0_rty_i};
 	assign {bus_socket_wb_slave_4_sel_o ,bus_socket_wb_slave_3_sel_o ,bus_socket_wb_slave_2_sel_o ,bus_socket_wb_slave_1_sel_o ,bus_socket_wb_slave_0_sel_o} =bus_socket_wb_slave_array_sel_o;
 	assign {bus_socket_wb_slave_4_stb_o ,bus_socket_wb_slave_3_stb_o ,bus_socket_wb_slave_2_stb_o ,bus_socket_wb_slave_1_stb_o ,bus_socket_wb_slave_0_stb_o} =bus_socket_wb_slave_array_stb_o;
 	assign {bus_socket_wb_slave_4_tag_o ,bus_socket_wb_slave_3_tag_o ,bus_socket_wb_slave_2_tag_o ,bus_socket_wb_slave_1_tag_o ,bus_socket_wb_slave_0_tag_o} =bus_socket_wb_slave_array_tag_o;
 	assign {bus_socket_wb_slave_4_we_o ,bus_socket_wb_slave_3_we_o ,bus_socket_wb_slave_2_we_o ,bus_socket_wb_slave_1_we_o ,bus_socket_wb_slave_0_we_o} =bus_socket_wb_slave_array_we_o;

 
//Wishbone slave address match
 /* ram wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[3]= ((bus_socket_wb_addr_map_0_grant_addr >= ram_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< ram_END_ADDR));
 /* gpo wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[1]= ((bus_socket_wb_addr_map_0_grant_addr >= gpo_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< gpo_END_ADDR));
 /* int_ctrl wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[4]= ((bus_socket_wb_addr_map_0_grant_addr >= int_ctrl_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< int_ctrl_END_ADDR));
 /* jtag_intfc wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[0]= ((bus_socket_wb_addr_map_0_grant_addr >= jtag_intfc_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< jtag_intfc_END_ADDR));
 /* ni wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[2]= ((bus_socket_wb_addr_map_0_grant_addr >= ni_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< ni_END_ADDR));
 endmodule

