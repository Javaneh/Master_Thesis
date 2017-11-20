`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2017 02:52:42 PM
// Design Name: 
// Module Name: Trigger
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


module Trigger( echoDone, rst, clk, trigger, done );
    parameter n1 = 9; // 9-bits
    parameter n2 = 27; // 6-bits
    parameter [ 1:0 ] setTriggerLow = 2'd0, Idle = 2'd1, Delay = 2'd2;
    input clk, echoDone, rst;
    output reg trigger, done;
    reg [ n1 - 1:0 ] delayCnt = 9'b111110011; // 499
    reg [ 1:0 ] PS = setTriggerLow, NS;
    reg [ n2 - 1:0 ] waitCnt = 27'b101111101011110000011111111; // 99999999
    
    // for simulation purposes
    //parameter n1 = 6; // 9-bits
    //parameter n2 = 14; // 6-bits
    //reg [ n1 - 1:0 ] delayCnt = 9'b110001;
    //reg [ n2 - 1:0 ] waitCnt = 27'b10011100010000; // 9999
    
    always @ ( rst or echoDone ) begin
        NS <= setTriggerLow;
        PS <= NS;
    end
    
    always @ ( posedge clk ) begin
        case ( PS )
            setTriggerLow: 
                begin
                    NS <= Idle;
                    trigger <= 0;
                    done <= 0;
                    delayCnt <= 9'b110001;
                end
            Idle:
                begin
                    // wait for 2 seconds
                    if ( waitCnt == 0 ) begin
                        NS <= Delay;
                        waitCnt <= 27'b10011100010000;
                    end
                    else begin
                        waitCnt <= waitCnt - 1;
                        NS <= PS;
                    end
                end
            Delay:
                begin
                    // set trigger high & wait for 10 us
                    trigger <= 1;
                    
                    if ( delayCnt == 0 ) begin
                        done <= 1;
                        NS <= setTriggerLow;
                    end
                    else begin
                        delayCnt <= delayCnt - 1;
                        NS <= PS;
                    end
                end
        endcase 
        PS <= NS;
    end
endmodule
