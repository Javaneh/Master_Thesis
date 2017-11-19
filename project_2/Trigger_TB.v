`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2017 03:40:37 PM
// Design Name: 
// Module Name: Trigger_TB
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


module Trigger_TB();
    reg clk, echo;
    wire trigger;
    
    Trigger Trigger_test( .clk( clk ), .echo( echo ), .trigger( trigger ) );
    
    initial clk = 0;
    always #10 clk = ~clk;
    
    initial begin
        #13 echo = 0;
        #2000000000;
        #2000000000 $finish;
    end
endmodule
