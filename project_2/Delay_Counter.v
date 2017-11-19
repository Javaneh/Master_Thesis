`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2017 03:29:42 PM
// Design Name: 
// Module Name: Delay_Counter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Delay_Counter( clk, enIn, enOut );
    parameter n = 9; // 9 bits
    input clk, enIn;
    output reg enOut;
    reg en;
    reg [ n - 1:0 ] delay = 500;
    
    always @ ( enIn ) begin
        if ( enIn )
            en = 1;
        else
            en = 0;        
    end
    
    always @ ( posedge clk ) begin
        if ( en ) begin
            delay <= delay - 1;
        end
        
        if ( delay == 0 ) begin
            delay <= 500;
        end
    end
endmodule
