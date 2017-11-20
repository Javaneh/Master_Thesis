`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2017 12:33:37 PM
// Design Name: 
// Module Name: PmodCLP_Top
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


module PmodCLP_Top( btnr, CLK, JB, JC );
    input btnr, CLK;
    output [ 7:0 ] JB;
    output [ 9:7 ] JC;
    
    reg [ 7:0 ] d10_1 = 8'h31;
	reg [ 7:0 ] d1_1 = 8'h30;
	reg [ 7:0 ] d10ths_1 = 8'h32;
	reg [ 7:0 ] d10_2 = 8'h33;
	reg [ 7:0 ] d1_2 = 8'h30;
	reg [ 7:0 ] d10ths_2 = 8'h34;
    
    PmodCLP PmodCLP_mod( .btnr( btnr ), .CLK( CLK ), 
						.d10_1( d10_1 ), .d1_1( d1_1 ), .d10ths_1( d10ths_1 ),
						.d10_2( d10_2 ), .d1_2( d1_2 ), .d10ths_2( d10ths_2 ),
						.JB( JB ), .JC( JC ) );
endmodule
