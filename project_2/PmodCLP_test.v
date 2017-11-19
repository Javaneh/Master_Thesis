`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2017 05:13:38 PM
// Design Name: 
// Module Name: PmodCLP_test
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


module PmodCLP_test();
    reg btnr, CLK;
    wire [ 9:7 ] JC;
    wire [ 7:0 ] JB;
    
    PmodCLP_Top PmodCLP_Top_mod_test( .btnr( btnr ), .CLK( CLK ), .JC( JC ), .JB( JB ) );
    
    initial CLK = 0;
    always #10 CLK = ~CLK;
endmodule
