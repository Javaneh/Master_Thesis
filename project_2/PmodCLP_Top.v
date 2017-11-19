`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2017 08:11:22 AM
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
    input btnr;
    //input changeValue;
    input CLK;
    output [ 7:0 ] JB;
    output [ 9:7 ] JC;
    
    reg [ 7:0 ] d10_1 = 8'h31;
    reg [ 7:0 ] d1_1 = 8'h30;
    reg [ 7:0 ] d10ths_1 = 8'h33;
    reg [ 7:0 ] d10_2 = 8'h34;
    reg [ 7:0 ] d1_2 = 8'h0;
    reg [ 7:0 ] d10ths_2 = 8'h35;
    
    always @ ( posedge CLK ) begin
        if ( d1_1 == 8'h39 || d1_2 == 8'h39 ) begin
            d1_1 <= 8'h30;
            d1_2 <= 8'h30;
        end
        else begin
            d1_1 <= d1_1 + 1'h1;
            d1_2 <= d1_2 + 1'h1;
        end
    end
    PmodCLP PmodCLP_mod( .btnr( btnr ), .CLK( CLK ), 
                        .d10_1( d10_1 ), .d1_1( d1_1 ), .d10ths_1( d10ths_1 ),
                        .d10_2( d10_2 ), .d1_2( d1_2 ), .d10ths_2( d10ths_2 ),
                        .JB( JB ), .JC( JC ) );
    
endmodule
