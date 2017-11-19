`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/05/2017 12:13:35 PM
// Design Name: 
// Module Name: LCDI_top
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


module LCDI_top(CLK, dataout, control);
    input CLK;
    output [3:0] dataout;
    output [2:0] control;
    
    //reg [39:0] dIn = 40'h123456789A;
    
    LCDI LCDIm( .clk( CLK ), .datain( 40'h123456789A ), .dataout( dataout ), .control( control ) );
endmodule
