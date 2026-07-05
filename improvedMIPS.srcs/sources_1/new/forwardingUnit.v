`timescale 1ns / 1ps

module forwardingUnit(
    input [4:0] id_ex_RS, 
    input [4:0] id_ex_RT, 
    
    input ex_mem_RegWrite, 
    input [4:0] ex_mem_RD,
    
    input mem_wb_RegWrite, 
    input [4:0] mem_wb_RD,
    
    output reg [1:0] forwardMuxASelect,
    output reg [1:0] forwardMuxBSelect

);

    always @(*) begin
    forwardMuxASelect = 2'b00;
        
    
        if(ex_mem_RegWrite && 
            ex_mem_RD != 5'b0 &&
            ex_mem_RD == id_ex_RS) begin
                
                forwardMuxASelect = 2'b10;
        end
        
        else if(mem_wb_RegWrite && 
            mem_wb_RD != 5'b0 &&
            mem_wb_RD == id_ex_RS) begin
                
                forwardMuxASelect = 2'b01;
        end
        
        else forwardMuxASelect = 2'b00;

    end
    
    
    
    
    
    
    
    
    
    always @(*) begin
    forwardMuxBSelect = 2'b00;
        
    
        if(ex_mem_RegWrite && 
            ex_mem_RD != 5'b0 &&
            ex_mem_RD == id_ex_RT) begin
                
                forwardMuxBSelect = 2'b10;
        end
        
        else if(mem_wb_RegWrite && 
            mem_wb_RD != 5'b0 &&
            mem_wb_RD == id_ex_RT) begin
                
                forwardMuxBSelect = 2'b01;
        end
        
        else forwardMuxBSelect = 2'b00;

    end
        
endmodule
