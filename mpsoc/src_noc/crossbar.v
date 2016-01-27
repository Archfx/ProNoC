`timescale	 1ns/1ps

module crossbar #(
	parameter V	= 4, 	// vc_num_per_port
	parameter P	= 5, 	// router port num
	parameter Fpay 	= 32,
	parameter MUX_TYPE="BINARY",		//"ONE_HOT" or "BINARY"
	parameter ADD_PIPREG_AFTER_CROSSBAR=0,
	parameter ADD_PIPREG_BEFORE_CROSSBAR=0
)
(
	granted_dest_port_all,
	flit_in_all,
	flit_out_all,
	flit_out_we_all,
	clk,
	reset

);	
	
	function integer log2;
      input integer number; 	begin	
         log2=0;	
         while(2**log2<number) begin	
            log2=log2+1;	
         end	
      end	
   endfunction // log2 
	
	localparam 	PV		=	V		*	P,
					VV		=	V		*	V,
					PP		=	P		*	P,					
					PVV	=	PV		*  V,	
					P_1	=	P-1	,
					VP_1	=	V		* 	P_1,				
					PP_1	=	P_1	*	P,
					PVP_1	=	PV		*	P_1;

	localparam 	Fw			=	2+V+Fpay,	//flit width;	
					PFw		=	P*Fw,
					P_1Fw		=	P_1	* Fw,
					P_1w		=	log2(P_1);
	
	
	input	[PP_1-1		:	0]	granted_dest_port_all;
	input	[PFw-1		:	0]	flit_in_all;
	output reg [PFw-1	:	0]	flit_out_all;
	output reg [P-1		:	0]	flit_out_we_all;
	input reset,clk;
	
	reg  [PP_1-1        :   0]  granted_dest_port_all_internal;
    reg  [PFw-1         :   0]  flit_in_all_internal;
	wire [PFw-1         :   0]  flit_out_all_internal;
    wire [P-1           :   0]  flit_out_we_all_internal;
	wire [P_1-1			:	0]	granted_dest_port [P-1		:	0];
	wire [P_1Fw-1		:	0]	mux_in				[P-1		:	0];
	wire [P_1-1			:	0]	mux_sel				[P-1		:	0];
	wire [P_1w-1		:	0]	mux_sel_bin			[P-1		:	0];
	wire [PP-1			:	0]	flit_out_we_gen;
	
	genvar i,j;
	generate
	for(i=0;i<P;i=i+1)begin : port_loop
		assign granted_dest_port[i] = granted_dest_port_all_internal[(i+1)*P_1-1	:	i*P_1];
		for(j=0;j<P;j=j+1)begin : port_loop2  //remove sender port flit from flit list
			if(i>j)	begin	:if1
				assign mux_in[i][(j+1)*Fw-1	:	j*Fw]= 	flit_in_all_internal[(j+1)*Fw-1	:	j*Fw];
				assign mux_sel[i][j] =	granted_dest_port[j][i-1];
			end
			else if(i<j) begin :if2
				assign mux_in[i][j*Fw-1	:	(j-1)*Fw]= 	flit_in_all_internal[(j+1)*Fw-1	:	j*Fw];
				assign mux_sel[i][j-1] =	granted_dest_port[j][i];
			end
		end//fior j
		
		if	(MUX_TYPE	==	"ONE_HOT") begin : one_hot_gen
			one_hot_mux #(
				.IN_WIDTH			(P_1Fw),
				.SEL_WIDTH			(P_1)
			)
			cross_mux
			(
				.mux_in				(mux_in [i]),
				.mux_out				(flit_out_all_internal[(i+1)*Fw-1	:	i*Fw]),
				.sel					(mux_sel[i])
	
			);
		end else begin : binary
		
			one_hot_to_bin #(
				.ONE_HOT_WIDTH		(P_1),
				.BIN_WIDTH			(P_1w)
			)
			conv
			(
				.one_hot_code	(mux_sel[i]),
				.bin_code		(mux_sel_bin[i])
		
			);
			
			
			binary_mux #(
				.IN_WIDTH			(P_1Fw),
				.OUT_WIDTH  		(Fw)
			)
			cross_mux
			(
				.mux_in				(mux_in [i]),
				.mux_out				(flit_out_all_internal[(i+1)*Fw-1	:	i*Fw]),
				.sel					(mux_sel_bin[i])
		
			);
		end//binary
	
	
	
	add_sw_loc_one_hot #(
		.P(P),
		.SW_LOC(i)
	)
	add_sw_loc(
		.destport_in(granted_dest_port_all_internal[(i+1)*P_1-1    :   i*P_1]),
		.destport_out(flit_out_we_gen[(i+1)*P-1   :   i*P])
	);
	
	
	end//for i	
	endgenerate
	
	custom_or #(
		.IN_NUM		(P),
		.OUT_WIDTH	(P)
	)wide_or
	(
		.or_in	(flit_out_we_gen),
		.or_out	(flit_out_we_all_internal)
	);
	
	
    generate 
        if(	ADD_PIPREG_AFTER_CROSSBAR == 1)begin :pip_reg1
    	    always @(posedge clk or posedge reset)begin 
    	       if(reset)begin
                    flit_out_all    <=  {PFw{1'b0}};
                    flit_out_we_all <=  {P{1'b0}};
               end else begin
                    flit_out_all     <=   flit_out_all_internal;
                    flit_out_we_all  <=   flit_out_we_all_internal;
               
               end
           end    	
    	end else begin    :no_pip_reg1	
    	   always @(*)begin 
               flit_out_all     =   flit_out_all_internal;
               flit_out_we_all  =   flit_out_we_all_internal;
           end
    	end
    	
    	
    	
    	if(ADD_PIPREG_BEFORE_CROSSBAR == 1)begin :pip_reg2
            always @(posedge clk or posedge reset)begin 
               if(reset)begin
                    granted_dest_port_all_internal  <={PP_1{1'b0}};
                    flit_in_all_internal            <={PFw{1'b0}};                    
               end else begin 
                    granted_dest_port_all_internal  <=granted_dest_port_all;
                    flit_in_all_internal            <=flit_in_all;                  
               end
             end  
        end else begin :no_pip_reg2
            always @(*)begin
                    granted_dest_port_all_internal  =granted_dest_port_all;
                    flit_in_all_internal            =flit_in_all;                  
            end  
        end   
        	
	endgenerate
	
	
	
	
endmodule
