`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineers: Dan Pederson, 2004
//				  Barron Barnett, 2004
//				  Jacob Beck, 2006
//				  Tudor Ciuleanu, 2007
//				  Josh Sackos, 2012
// 
// Create Date:    13:03:39 06/26/2012 
// Module Name:    PmodCLP 
// Project Name:   PmodCLP_Demo
// Target Devices: Nexys3
// Tool versions:  ISE 14.1
// Description: Displays "Hello from Digilent" text on the PmodCLP LCD screen.
//
// Revision: 6
// Revision 0.01 - File Created
// Revision History:								    
//		 05/27/2004(DanP):  created
//		 07/01/2004(BarronB): (optimized) and added writeDone as output
//		 08/12/2004(BarronB): fixed timing issue on the D2SB
//		 12/07/2006(JacobB): Revised code to be implemented on a Nexys Board
//						Changed "Hello from Digilent" to be on one line"
//						Added a Shift Left command so that the message
//						"Hello from Diligent" is shifted left by 1 repeatedly
//						Changed the delay of character writes
//		 11/21/2007(TudorC): Revised code to work with the CLP module.
//						Removed the write state machine and other unnecessary signals
//						Added backlight toggling
//		 08/17/2011(MichelleY): remove the backlight toggling
//									modify to be compatible with Nexys2 master UCF
//		 06/26/2012(JoshS): Converted VHDL to Verilog
//////////////////////////////////////////////////////////////////////////////////


// ==============================================================================
// 										  Define Module
// ==============================================================================
module PmodCLP( btnr, d10_1, d1_1, d10ths_1, d10_2, d1_2, d10ths_2, CLK, JB, JC );

	// ===========================================================================
	// 										Port Declarations
	// ===========================================================================
		input btnr;								// use BTNR as reset input
		input CLK;								// 100 MHz clock input
		input [ 7:0 ] d10_1, d1_1, d10ths_1;
		input [ 7:0 ] d10_2, d1_2, d10ths_2;
		//lcd input signals
		//signal on connector JB
		output [ 7:0 ] JB;						//output bus, used for data transfer (DB)
	
		// signal on connector JC
		//JC[7]register selection pin  (RS)
		//JC[8]selects between read/write modes (RW)
		//JC[9]enable signal for starting the data read/write (E)
		output [ 9:7 ] JC;

	// ===========================================================================
	// 							  Parameters, Regsiters, and Wires
	// ===========================================================================
		wire [ 7:0 ] JB;
		wire [ 9:7 ] JC;

		//LCD control state machine
		parameter [ 3:0 ]  stFunctionSet = 0,						// Initialization states
							stDisplayCtrlSet = 1,
							stDisplayClear = 2,
							stPowerOn_Delay = 3,					// Delay states
							stFunctionSet_Delay = 4,
							stDisplayCtrlSet_Delay = 5,
							stDisplayClear_Delay = 6,
							stInitDne = 7,							// Display characters and perform standard operations
							stActWr = 8,
							stCharDelay = 9;						// Write delay for operations
	                        //stDoNothing = 10;
	
		/* These constants are used to initialize the LCD pannel.

			--  FunctionSet:
								Bit 0 and 1 are arbitrary
								Bit 2:  Displays font type(0=5x8, 1=5x11)
								Bit 3:  Numbers of display lines (0=1, 1=2)
								Bit 4:  Data length (0=4 bit, 1=8 bit)
								Bit 5-7 are set
			--  DisplayCtrlSet:
								Bit 0:  Blinking cursor control (0=off, 1=on)
								Bit 1:  Cursor (0=off, 1=on)
								Bit 2:  Display (0=off, 1=on)
								Bit 3-7 are set
			--  DisplayClear:
								Bit 1-7 are set	*/
		
		reg [ 6:0 ] clkCount = 7'b0000000;
		reg [ 20:0 ] count = 21'b000000000000000000000;	// 21 bit count variable for timing delays
		wire delayOK;								// High when count has reached the right delay time
		reg oneUSClk = 0;								// Signal is treated as a 1 MHz clock	
		reg [ 3:0 ] stCur = stPowerOn_Delay;			// LCD control state machine
		reg [ 3:0 ] stNext;
		wire writeDone;									// Command set finish
		reg [ 9:0 ] LCD_CMDS;

		  
		always @ ( lcd_cmd_ptr )
			case ( lcd_cmd_ptr )
				0: LCD_CMDS <= { 2'b00, 8'h3C }; // 0, Function Set
				1: LCD_CMDS <= { 2'b00, 8'h0C }; // 1, Display ON, Cursor OFF, Blink OFF
				2: LCD_CMDS <= { 2'b00, 8'h01 }; // 2, Clear Display
				3: LCD_CMDS <= { 2'b00, 8'h02 }; // 3, Return Home // initially 02...changing for funsies
				4: LCD_CMDS <= { 2'b10, 8'h53 }; // 4, S
				5: LCD_CMDS <= { 2'b10, 8'h31 }; // 5, 1
				6: LCD_CMDS <= { 2'b10, 8'h3A }; // 6, :
				7: LCD_CMDS <= { 2'b10, 8'h10 }; // 7, blank
				8: LCD_CMDS <= { 2'b00, 8'hC0 }; // 12, go to bottom left corner
				9: LCD_CMDS <= { 2'b10, 8'h53 }; // 13, S
				10: LCD_CMDS <= { 2'b10, 8'h32 }; // 14, 2
				11: LCD_CMDS <= { 2'b10, 8'h3A }; // 15, :
				12: LCD_CMDS <= { 2'b10, 8'h10 }; // 16, blank
		      /*13: LCD_CMDS <= { 2'b00, 8'h85 };
		      14: LCD_CMDS <= { 2'b10, 8'h35 }; // d10_1
		      15: LCD_CMDS <= { 2'b10, d1_1 };
		      16: LCD_CMDS <= { 2'b10, 8'h2E };
		      17: LCD_CMDS <= { 2'b10, d10ths_1 };
		      18: LCD_CMDS <= { 2'b00, 8'hC5 };
		      19: LCD_CMDS <= { 2'b10, d10_2 };
		      20: LCD_CMDS <= { 2'b10, d1_2 };
		      21: LCD_CMDS <= { 2'b10, 8'h2E };
		      22: LCD_CMDS <= { 2'b10, d10ths_2 };*/
		  endcase

		reg [ 3:0 ] lcd_cmd_ptr;

	// ===========================================================================
	// 										Implementation
	// ===========================================================================

		// This process counts to 100, and then resets.  It is used to divide the clock signal.
		// This makes oneUSClock peak aprox. once every 1microsecond
		always @ ( posedge CLK ) begin

			if( clkCount == 7'b0110010 ) begin // before was: 7'b1100100
				clkCount <= 7'b0000000;
				oneUSClk <= ~oneUSClk;
			end
			else begin
				clkCount <= clkCount + 1'b1;
			end

		end


		// This process increments the count variable unless delayOK = 1.
		always @ ( posedge oneUSClk ) begin
	
			if ( delayOK == 1'b1 ) begin
				count <= 21'b000000000000000000000;
			end
			else begin
				count <= count + 1'b1;
			end
	
		end

		// Determines when count has gotten to the right number, depending on the state.
		assign delayOK = (
					( ( stCur == stPowerOn_Delay ) && ( count == 21'b111101000010010000000 ) ) ||			// 2000000		-> 20 ms
					( ( stCur == stFunctionSet_Delay ) && ( count == 21'b000000000111110100000 ) ) ||		// 4000 		-> 40 us
					( ( stCur == stDisplayCtrlSet_Delay ) && ( count == 21'b000000000111110100000 ) ) ||	// 4000 		-> 40 us
					( ( stCur == stDisplayClear_Delay ) && ( count == 21'b000100111000100000000 ) ) ||		// 160000 		-> 1.6 ms
					//( ( stCur == stCharDelay ) && ( count == 21'b00000000001111101000 ) )					// changed to 20 us// 260000		-> 2.6 ms - Max Delay for character writes and shifts
					( ( stCur == stCharDelay ) && ( count == 21'b000111111011110100000 ) )					// 260000		-> 2.6 ms - Max Delay for character writes and shifts
		) ? 1'b1 : 1'b0;
		
		// For simulation purposes
		/*assign delayOK = (
                            ( ( stCur == stPowerOn_Delay ) && ( count == 21'd2000 ) ) ||            // 2000000        -> 20 ms
                            ( ( stCur == stFunctionSet_Delay ) && ( count == 21'd4 ) ) ||        // 4000         -> 40 us
                            ( ( stCur == stDisplayCtrlSet_Delay ) && ( count == 21'd4) ) ||    // 4000         -> 40 us
                            ( ( stCur == stDisplayClear_Delay ) && ( count == 21'd160 ) ) ||        // 160000         -> 1.6 ms
                            ( ( stCur == stCharDelay ) && ( count == 21'd260 ) )                    // 260000        -> 2.6 ms - Max Delay for character writes and shifts
                ) ? 1'b1 : 1'b0;*/
                
		// writeDone goes high when all commands have been run	
		assign writeDone = ( lcd_cmd_ptr == 4'b1101 ) ? 1'b1 : 1'b0; // need to change this or remove this maybe
        
		// Increments the pointer so the statemachine goes through the commands
		always @ ( posedge oneUSClk ) begin
			if ( ( stNext == stInitDne || stNext == stDisplayCtrlSet || stNext == stDisplayClear ) && writeDone == 1'b0 ) begin
				lcd_cmd_ptr <= lcd_cmd_ptr + 1'b1;
			end
			if ( writeDone ) begin
			    lcd_cmd_ptr <= 4'b0011;
			end
			else if ( stCur == stPowerOn_Delay || stNext == stPowerOn_Delay ) begin
				lcd_cmd_ptr <= 4'b0000;
			end
			else begin
				lcd_cmd_ptr <= lcd_cmd_ptr;
			end
		end
	
		// This process runs the LCD state machine
		always @ ( posedge oneUSClk ) begin
			if ( btnr == 1'b1 ) begin
				stCur <= stPowerOn_Delay;
			end
			else begin
				stCur <= stNext;
			end
		end
	

		// This process generates the sequence of outputs needed to initialize and write to the LCD screen
		always @ ( stCur or delayOK or writeDone or lcd_cmd_ptr ) begin
			case ( stCur )
				// Delays the state machine for 20ms which is needed for proper startup.
				stPowerOn_Delay : 
				begin
					if ( delayOK == 1'b1 ) begin
						stNext <= stFunctionSet;
					end
					else begin
						stNext <= stPowerOn_Delay;
					end
				end
					
				// This issues the function set to the LCD as follows 
				// 8 bit data length, 1 lines, font is 5x8.
				stFunctionSet : 
				begin
					stNext <= stFunctionSet_Delay;
				end
				
				// Gives the proper delay of 37us between the function set and
				// the display control set.
				stFunctionSet_Delay : 
				begin
					if ( delayOK == 1'b1 ) begin
						stNext <= stDisplayCtrlSet;
					end
					else begin
							stNext <= stFunctionSet_Delay;
					end
				end
				
				// Issuse the display control set as follows
				// Display ON,  Cursor OFF, Blinking Cursor OFF.
				stDisplayCtrlSet : 
				begin
					stNext <= stDisplayCtrlSet_Delay;
				end

				// Gives the proper delay of 37us between the display control set
				// and the Display Clear command. 
				stDisplayCtrlSet_Delay : 
				begin
					if ( delayOK == 1'b1 ) begin
						stNext <= stDisplayClear;
					end
					else begin
						stNext <= stDisplayCtrlSet_Delay;
					end
				end
				
				// Issues the display clear command.
				stDisplayClear	: 
				begin
					stNext <= stDisplayClear_Delay;
				end

				// Gives the proper delay of 1.52ms between the clear command
				// and the state where you are clear to do normal operations.
				stDisplayClear_Delay : 
				begin
					if ( delayOK == 1'b1 ) begin
						stNext <= stInitDne;
					end
					else begin
						stNext <= stDisplayClear_Delay;
					end
				end
				
				// State for normal operations for displaying characters, changing the
				// Cursor position etc.
				stInitDne : 
				begin		
					stNext <= stActWr;
				end

				// stActWr
				stActWr : 
				begin
    					stNext <= stCharDelay;
				end
					
				// Provides a max delay between instructions.
				stCharDelay : 
				begin
					if ( delayOK == 1'b1 ) begin
						stNext <= stInitDne;
					end
					else begin
						stNext <= stCharDelay;
					end
				end
				default : stNext <= stPowerOn_Delay;

			endcase
		end
		
		
		// Assign outputs
		assign JC[ 7 ] = LCD_CMDS[ 9 ]; //LCD_CMDS[lcd_cmd_ptr][ 9 ];
		assign JC[ 8 ] = LCD_CMDS[ 8 ]; //LCD_CMDS[lcd_cmd_ptr][ 8 ];
		assign JB = LCD_CMDS[ 7:0 ]; //LCD_CMDS[lcd_cmd_ptr][ 7:0 ];
		assign JC[ 9 ] = (stCur == stFunctionSet || stCur == stDisplayCtrlSet || stCur == stDisplayClear || stCur == stActWr) ? 1'b1 : 1'b0;
endmodule
