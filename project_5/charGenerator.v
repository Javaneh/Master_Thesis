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
module charGenerator( LCD_SetUp_Done, CLK, dOut, ctrl, done );

	input LCD_SetUp_Done;					// LCd Set Up Done Signal
	input CLK;								// 100 MHz clock input
	
	//lcd input signals
	//signal on connector JB
	output [ 7:0 ] dOut;						//output bus, used for data transfer (DB)

	// signal on connector JC
	//JC[7]register selection pin  (RS)
	//JC[8]selects between read/write modes (RW)
	//JC[9]enable signal for starting the data read/write (E)
	output [ 2:0 ] ctrl;
    output done;
    
	// wires, registers & parameters
	wire [ 7:0 ] dOut;
	wire [ 2:0 ] ctrl;

	//LCD control state machine
	parameter [ 2:0 ]  stInitDne = 4,
						stActWr = 1,
						stCharDelay = 2,
						stWriteDne = 3,
						stDoNothing = 0;						// Write delay for operations
	
	
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
	reg [ 3:0 ] stCur;// = stDoNothing;			// LCD control state machine
	reg [ 3:0 ] stNext;
	wire writeDone;									// Command set finish
	reg [ 9:0 ] LCD_CMDS;
		  
	always @ ( lcd_cmd_ptr )
		case ( lcd_cmd_ptr )
			0: LCD_CMDS <= { 2'b10, 8'h53 }; // 4, S
			1: LCD_CMDS <= { 2'b10, 8'h31 }; // 5, 1
			2: LCD_CMDS <= { 2'b10, 8'h3A }; // 6, :
			3: LCD_CMDS <= { 2'b10, 8'h10 }; // 7, blank
			4: LCD_CMDS <= { 2'b00, 8'hC0 }; // 12, go to bottom left corner
			5: LCD_CMDS <= { 2'b10, 8'h53 }; // 13, S
			6: LCD_CMDS <= { 2'b10, 8'h32 }; // 14, 2
			7: LCD_CMDS <= { 2'b10, 8'h3A }; // 15, :
			8: LCD_CMDS <= { 2'b10, 8'h10 }; // 16, blank
		endcase
			
	reg [ 3:0 ] lcd_cmd_ptr;

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
				( ( stCur == stCharDelay ) && ( count == 21'b000111111011110100000 ) )					// 260000		-> 2.6 ms - Max Delay for character writes and shifts
	) ? 1'b1 : 1'b0;
		
	// writeDone goes high when all commands have been run	
	assign writeDone = ( lcd_cmd_ptr == 4'b1001 ) ? 1'b1 : 1'b0; // need to change this or remove this maybe


	// Increments the pointer so the statemachine goes through the commands
	always @ ( posedge oneUSClk ) begin
		if ( ( stNext == stInitDne ) && writeDone == 1'b0 ) begin
			lcd_cmd_ptr <= lcd_cmd_ptr + 1'b1;
		end
		else begin
			lcd_cmd_ptr <= lcd_cmd_ptr;
		end
	end
	
		// This process runs the LCD state machine
		always @ ( posedge oneUSClk ) begin
			stCur <= stNext;
		end
	
		always @ ( LCD_SetUp_Done ) begin
			if ( LCD_SetUp_Done )
				stNext <= stInitDne;
			else
				stNext <= stDoNothing;
		end
		
		// This process generates the sequence of outputs needed to initialize and write to the LCD screen
		always @ ( stCur or delayOK or writeDone or lcd_cmd_ptr ) begin
			case ( stCur )
				// State for normal operations for displaying characters, changing the
				// Cursor position etc.
				stInitDne : 
				begin		
					stNext <= stActWr;
				end

				// stActWr
				stActWr : 
				begin
					if ( writeDone )
						stNext <= stWriteDne;
					else
						stNext <= stCharDelay;
				end
					
				// Provides a max delay between instructions.
				stCharDelay : 
				begin
					if ( delayOK == 1'b1 ) begin
						stNext <= stInitDne;
					end
					else if ( writeDone ) begin
						stNext <= stWriteDne;
					end
					else begin
						stNext <= stCharDelay;
					end
				end
				
				stWriteDne :
				begin
					stNext <= stDoNothing;
				end

				stDoNothing :
				begin
					stNext <= stDoNothing;
				end
				default : stNext <= stInitDne;

			endcase
		end
		
		
		// Assign outputs
		assign ctrl[ 0 ] = LCD_CMDS[ 9 ]; //LCD_CMDS[lcd_cmd_ptr][ 9 ];
		assign ctrl[ 1 ] = LCD_CMDS[ 8 ]; //LCD_CMDS[lcd_cmd_ptr][ 8 ];
		assign dOut = LCD_CMDS[ 7:0 ]; //LCD_CMDS[lcd_cmd_ptr][ 7:0 ];
		assign ctrl[ 2 ] = ( stCur == stActWr ) ? 1'b1 : 1'b0;
		assign done = ( stCur == stActWr ) ? 1'b1 : 1'b0;
endmodule
