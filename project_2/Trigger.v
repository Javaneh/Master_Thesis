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


module Trigger( echo, clk, trigger, done );
    parameter n = 9; // 9-bits
    parameter [ 1:0 ] setTriggerLow = 2'd0, Idle = 2'd1, Delay = 2'd2;
    input clk, echo;
    output reg trigger, done;
    reg [ n - 1:0 ] delayCnt = 9'd499;
    reg [ 1:0 ] PS = setTriggerLow, NS;
    reg [ 26:0 ] waitCnt = 27'd99999999; //27'd49999999 // 27'd100000000
    
    always @ ( PS ) begin
        case ( PS )
            setTriggerLow: 
                begin
                    // set trigger low
                    if ( echo )
                    begin
                        trigger <= 0;
                        done <= 0;
                        NS <= Idle;
                    end
                    else
                        NS <= PS;
                end
            Idle:
                begin
                    // wait for 2 seconds
                    if ( waitCnt == 0 ) begin
                        NS <= Delay;
                    end
                    else begin
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
                        NS <= PS;
                    end
                end
        endcase 
        PS <= NS;
    end
    always @ ( posedge clk ) begin
        case ( PS )
            setTriggerLow:
                begin
                    delayCnt <= 9'd499;
                end
            Idle:
                begin
                    waitCnt <= waitCnt - 1;
                end
            Delay:
                begin
                    waitCnt <= 27'd99999999;
                    delayCnt <= delayCnt - 1;
                end
        endcase
    end
endmodule
