/**************************************
* Module: traffic_gen_verilator
* Date:2015-01-16  
* Author: alireza     
*
* Description: 
***************************************/
module  traffic_gen_verilator (
    ratio,
    pck_size,
    pck_number,
    current_x,
    current_y,
    reset,
    clk,
    start,
    sent_done,
    update, // update the noc_analayzer
    distance,
    msg_class,
    time_stamp_h2h,
    time_stamp_h2t,
   
    flit_out,     
    flit_out_wr,   
    credit_in,
    flit_in,   
    flit_in_wr,   
    credit_out,     
    report
);

    function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
   endfunction // log2  

    function integer CORE_NUM;
        input integer x,y;
        begin
            CORE_NUM = ((y * NX) +  x);
        end
    endfunction
    
    `define   INCLUDE_PARAM
    
    `include "parameter.v"
    
    
    
    localparam      Xw          =   log2(NX),   // number of node in x axis
                    Yw          =  log2(NY),    // number of node in y axis
                    Cw          =  (C > 1)? log2(C): 1,
                    Fw          =   2+V+Fpay,
                    RATIOw      =   log2(100),
                    PCK_CNTw    =   log2(MAX_PCK_NUM+1),
                    CLK_CNTw    =   log2(MAX_SIM_CLKs+1),
                    PCK_SIZw    =   log2(MAX_PCK_SIZ+1);

    
    
    
    
    input reset, clk;
    input  [RATIOw-1                :0] ratio;
    input                               start;
    output                              update;
    output [CLK_CNTw-1              :0] time_stamp_h2h,time_stamp_h2t;
    output [31                      :0] distance;
    output [Cw-1                    :0] msg_class;
    input  [Xw-1                    :0] current_x;
    input  [Yw-1                    :0] current_y;
    output [PCK_CNTw-1              :0] pck_number;
    input  [PCK_SIZw-1              :0] pck_size;
    output sent_done;
    
    
    // NOC interfaces
    output  [Fw-1                   :0] flit_out;     
    output                              flit_out_wr;   
    input   [V-1                    :0] credit_in;
    
    input   [Fw-1                   :0] flit_in;   
    input                               flit_in_wr;   
    output  [V-1                    :0] credit_out;     
    
    input                               report;
    
   
    

     traffic_gen #(
                .V(V),
                .P(P),
                .B(B),
                .NX(NX),
                .NY(NY),
                .Fpay(Fpay),
                .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
                .TOPOLOGY(TOPOLOGY),
                .ROUTE_NAME(ROUTE_NAME),
                .ROUTE_TYPE(ROUTE_TYPE),
                .TRAFFIC(TRAFFIC),
                .HOTSPOT_PERCENTAGE(HOTSPOT_PERCENTAGE),
                .HOTSOPT_NUM(HOTSOPT_NUM),
                .HOTSPOT_CORE_1(HOTSPOT_CORE_1),
                .HOTSPOT_CORE_2(HOTSPOT_CORE_2),
                .HOTSPOT_CORE_3(HOTSPOT_CORE_3),
                .HOTSPOT_CORE_4(HOTSPOT_CORE_4),
                .HOTSPOT_CORE_5(HOTSPOT_CORE_5),
                .C(C),
                .C0_p(C0_p),
                .C1_p(C1_p),  
                .C2_p(C2_p),  
                .C3_p(C3_p),      
                .MAX_PCK_NUM(MAX_PCK_NUM),
                .MAX_SIM_CLKs(MAX_SIM_CLKs),
                .MAX_PCK_SIZ(MAX_PCK_SIZ),
                .TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM)
            )
            the_traffic_gen
            (
                .pck_size(pck_size),
                .ratio (ratio),
                .pck_number(pck_number),
                .reset(reset),
                .clk(clk),
                .start(start),
                .sent_done(sent_done),
                .update(update),
                .time_stamp_h2h(time_stamp_h2h),
                .time_stamp_h2t(time_stamp_h2t),
                .distance(distance),
                .msg_class(msg_class),
                .current_x(current_x),
                .current_y(current_y),
                .flit_out(flit_out),  
                .flit_out_wr(flit_out_wr),  
                .credit_in(credit_in), 
                .flit_in(flit_in),  
                .flit_in_wr(flit_in_wr),  
                .credit_out(credit_out),
                .report (report)
            );
        
        

endmodule

