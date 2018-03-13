// CSCB58 Winter 2018 Final Project
// Bubble Trouble Knockoff
// Names: Jeffrey So, Ricky Chen, Byron Leung, Brandon Shewnarain
// Description: Insert Description Here

module project
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [4:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
	wire go, load_game, game_pause, play;
	assign go = ~KEY[4];
	
    // Instansiate datapath
	 datapath d0(.resetn(resetn), .pos(SW[6:0]), .col_in(SW[9:7]), .loadX(control_x), .loadY(control_y), .clk(CLOCK_50), .x(x), .y(y), .colour(colour));
	
    // Instansiate FSM control
    control c0(.clk(CLOCK_50), .resetn(resetn), .go(go), .load_game(load_game), .game_pause(game_pause), .play(play));
    
endmodule

module control(clk, resetn, go, load_game, game_pause, play);
	input clk, resetn, go;
	output load_game, game_pause, play;

	reg [2:0] state, state_next; // current state, next state
	localparam LEVEL_SELECT = 3'b000, LOAD_LEVEL = 3'b001, LEVEL_PAUSE = 3'b010, PLAY_START = 3'b011, PLAY = 3'b100, GAME_OVER = 3'b101; // states

	always@(*)
    begin: state_table
        case (state)
            LEVEL_SELECT: begin
				if (go) state_next <= LOAD_LEVEL;
                else state_next <= LEVEL_SELECT;
            end

            LOAD_LEVEL: begin
				if (!go) state_next <= LEVEL_PAUSE;
					else state_next <= LOAD_LEVEL;
            end

            LEVEL_PAUSE: begin
				if (go) state_next <= PLAY_START;
					else state_next <= LEVEL_PAUSE;
				end

            PLAY_START: begin
				if (!go) state_next <= PLAY;
					else state_next <= PLAY_START;
				end

				PLAY: begin
				if (go) state_next <= LEVEL_PAUSE;
					else state_next <= LOAD_LEVEL; // Not sure which state this should be
				end

            default: state_next = LEVEL_SELECT;
        endcase
    end // state_table
    
    // State Registers
    always @(posedge clk)
    begin: state_FFs
        if(resetn == 1'b0)
            state <= LEVEL_SELECT; // Should set reset state to state A
        else
            state <= state_next;
    end // state_FFS

    // Output logic
    assign load_game = (state == LOAD_LEVEL);
	 assign game_pause = (state == LEVEL_PAUSE);
	 assign play = (state == PLAY);

endmodule

module datapath(
	input clk,
	input resetn,
	input left,
	input right,
	input col_in, // Created to successfully compile prob will be removed.
	input loadX, // Created to successfully compile prob will be removed.
	input loadY,// Created to successfully compile prob will be removed.
	input pos,// Created to successfully compile prob will be removed.
   output reg [7:0] x,
	output reg [6:0] y,
	output reg [2:0] colour,
	output reg [7:0] data_result,
	output reg [1:0] lives
   ); 
	reg [4:0] FSM;
	 
   // input registers
   reg [7:0] playerX;
	reg [6:0] playerY;
	
	reg [27:0] counter;
	reg [27:0] counter2;
	
   // output of the alu
	reg [7:0] x_alu;
	reg [6:0] y_alu;
	reg[4:0] count;
	reg[4:0] clear;
	reg[4:0] draw;
	
	// enemy movement and position
	reg [7:0] enemyX;
	reg [6:0] enemyY;
	reg [7:0] enemyleft;
	reg [6:0] enemyright;
	reg [7:0] enemyup;
	reg [6:0] enemydown;

	
	always@(posedge clk) begin
	   if(!resetn) begin
			  FSM <= 4'd0;
		end
		
		else if (counter == 28'd50000) begin 
			// if FSM = 0, sets the positions of the user's block
			if (FSM == 4'd0) begin 
				if(count == 4'd2) begin
					
					// movement left of the user's block
					if (~left) begin
						if(playerX == 0) begin
							playerX <= 0;
						end

						else begin
							playerX <= playerX - 16;
					end
					
					// movement right of the user's block
					// Not sure what this end does
					end 
						
					if(~right) begin
							
						if(playerX == 160) begin
							playerX <= 160;
						end

						else begin
							playerX <= playerX + 16;
						end
					end
						
					count <= 4'd0;
				end
				// setting initial position
				playerX <= 80;
				playerY <= 100;
				FSM <= 1;
			end
			  
			// if FSM = 1, draw the player's block and sets FSM to 3
			else if(FSM == 4'b1) begin
				y <= playerY;
				x <= playerX;
				//Set colour of player
				colour <= 3'b111;
				FSM <= 3;
				clear <=1;
			end
			
			// if FSM = 2, erase the previous position of the player block
			else if (FSM == 4'd2)begin

				x <= playerX;
				y <= playerY;
				colour <= 3'b000;
				
				FSM <= 9;
			end
			
			// if FSM = 3, animate the position of the falling blocks
			else if(FSM == 4'd3) begin
			  
				if(enemyleft <= 1) begin
					enemyX <= enemyX - 4;
				end
					
				if(enemyright <= 1) begin
					enemyX <= enemyX + 4;
				end
					
				if(enemyup <= 1) begin
					enemyY <= enemyY - 4;
				end
					
				if(enemydown <= 1) begin
					enemyY <= enemyY + 4;
				end
				 
				draw <= 1;
				FSM <= 4;
			end
			
			// if FSM = 4, wait state
			else if (FSM == 4'd4) begin
				FSM <= 5;
			end
			  
			// if FSM = 5, wait state
			else if(FSM == 4'd5) begin
				FSM <= 6;
			end 
			
			// if FSM = 6, wait state
			else if (FSM == 4'd6) begin
				FSM <= 7;
			end
			
			// if FSM = 7, wait state
			else if (FSM == 4'd7) begin
				FSM <= 8;
			end
			
			// if FSM = 8, wait state
			else if (FSM == 4'd8) begin
				FSM <= 2;
			end
			  
			// if FSM = 9, updates the position for the falling blocks and checks the collisions
			else if(FSM == 4'd9) begin
				// collision to enemy
				if(playerX == enemyX && playerY == enemyY) begin
					// update lives count
					lives <= lives - 1;
					// update the position     i dont really understand what this if statement does
					if((playerX + 30) > 120) begin
						enemyX <= 30;
					end
					else begin
						enemyX <= (playerX + 30);
					end
					enemyY <= 0;
				end
					
				// if enemy hits the edges of the screen
				//Change this number when we decide how big the enemy is
				//Right Edge
				if (enemyX == 160) begin
					enemyleft <= 1'b1;
					enemyright <= 1'b0;
				end
				//Left Edge
				if (enemyX == 0) begin
					enemyleft <= 1'b0;
					enemyright <= 1'b1;
				end
				//Top Edge
				if (enemyY == 0) begin
					enemyup <= 1'b0;
					enemydown <= 1'b1;
				end
				//Bottom Edge
				if (enemyY == 120) begin
					enemyup <= 1'b1;
					enemydown <= 1'b0;
				end
		
				FSM <= 0;
			end
			
			// if FSM = 10, wait state
			else if(FSM == 4'd10) begin
				FSM <= 2;
			end
			// set the counter back to 0
			counter <= 28'd0;  
			
			// slow down the input, so the player block doesn't move too fast
			count <= count + 1;

	    end
		 
		else begin
			// this block operates outside of the rate divider and used for drawing and clearing falling blocks
			// increase counter, used as a rate divider
		 	counter <= counter + 1;
			
			// if clear = 1, signal for erasing the 1st falling block
			if(clear == 4'd1) begin
				x <= enemyX;
				y <= enemyY;
					
				colour <= 1'b000;
				clear <= 2;
			end
			// if clear = 2, signal for erasing the 2nd falling block
			else if(clear == 4'd2) begin
				x <= enemyleft;
				y <= enemyright;
				clear <= 3;
			end
			// if clear = 3, signal for erasing the 3rd falling block
			else if(clear == 4'd3) begin
				x <= enemyup;
				y <= enemydown;
				clear <= 0;
			end
			  
			// if draw = 1, draw the 1st falling block
			if(draw == 4'd1) begin
				x <= enemyX;
				y <= enemyY;

				colour <= 3'b110;
				draw <= 2;
			end
			// if draw = 2, draw the 2nd falling block
			else if(draw == 4'd2) begin  
				x <= enemyleft;
				y <= enemyright;
				
				colour <= 3'b011;
				draw <= 3;
			end
			// if draw = 3, draw the 3rd falling block
			else if(draw == 4'd3) begin  
				x <= enemyup;
				y <= enemydown;
				
				colour <= 3'b100;
				draw <= 0;
			end
	    end
end
endmodule

// hex display
module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule
