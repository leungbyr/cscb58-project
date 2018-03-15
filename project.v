// CSCB58 Winter 2018 Final Project
// Bubble Trouble Knockoff
// Names: Jeffrey So, Ricky Chen, Byron Leung, Brandon Shewnarain
// Description: Insert Description Here

`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

module project
    (
        CLOCK_50,                       //  On Board 50 MHz
        // Your inputs and outputs here
        KEY,
        SW,
        LEDR,
        // The ports below are for the VGA output.  Do not change.
        VGA_CLK,                        //  VGA Clock
        VGA_HS,                         //  VGA H_SYNC
        VGA_VS,                         //  VGA V_SYNC
        VGA_BLANK_N,                        //  VGA BLANK
        VGA_SYNC_N,                     //  VGA SYNC
        VGA_R,                          //  VGA Red[9:0]
        VGA_G,                          //  VGA Green[9:0]
        VGA_B                           //  VGA Blue[9:0]
    );

    input           CLOCK_50;               //  50 MHz
    input   [9:0]   SW;
    input   [3:0]   KEY;
    output [10:0] LEDR;
    // Declare your inputs and outputs here
    // Do not change the following outputs
    output          VGA_CLK;                //  VGA Clock
    output          VGA_HS;                 //  VGA H_SYNC
    output          VGA_VS;                 //  VGA V_SYNC
    output          VGA_BLANK_N;                //  VGA BLANK
    output          VGA_SYNC_N;             //  VGA SYNC
    output  [9:0]   VGA_R;                  //  VGA Red[9:0]
    output  [9:0]   VGA_G;                  //  VGA Green[9:0]
    output  [9:0]   VGA_B;                  //  VGA Blue[9:0]
    
    wire resetn;
    assign resetn = SW[0];
    
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
    
    assign go = ~KEY[0];
    assign left = ~KEY[3];
    assign right = ~KEY[2];
    
    wire load_level, level_pause, play; // game states
    wire [7:0] playerX, playerY, enemyX, enemyY;
    wire [2:0] ani_state;
    wire player_move, animate_done;
    
    // DEBUGGING
    // assign LEDR[0] = load_level;
    // assign LEDR[1] = level_pause;
    // assign LEDR[2] = play;
    
    datapath d0(
        .playerX(playerX),
        .playerY(playerY),
        .enemyX(enemyX),
        .enemyY(enemyY),
        .ani_state(ani_state),
        .resetn(resetn),
        .clk(CLOCK_50),
        .ani_done(animate_done),
        .x(x),
        .y(y),
        .colour(colour),
        .drawEn(writeEn)
    );
    
    control c0(
        .go(go),
        .resetn(resetn),
        .clk(CLOCK_50),
        .load_level(load_level),
        .level_pause(level_pause),
        .play(play)
    );
    
    player_control pc0(
        .left(left),
        .right(right),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .move(player_move),
        .playerX(playerX),
        .playerY(playerY),
        .enemyX(enemyX),
        .enemyY(enemyY)
    );
    
    animate_control ac0(
        .load_level(load_level),
        .player_move(player_move),
        .ani_done(animate_done),
        .resetn(resetn),
        .clk(CLOCK_50),
        .ani_state(ani_state)
    );
    
    enemy_control ec0(
        .size(3'd3),
        .start_x(8'd80),
        .start_y(7'd60),
        .d_x(1),
        .d_y(1),
        .leftwards(0),
        .upwards(0),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .enemyX(enemyX),
        .enemyY(enemyY)
    );
endmodule

// Controls game states
module control(go, resetn, clk, load_level, level_pause, play);
    input go, resetn, clk;
    output load_level, level_pause, play;
    
    reg [2:0] state, state_next;
    localparam LEVEL_SELECT = 3'b000, LOAD_LEVEL = 3'b001, LEVEL_PAUSE = 3'b010,    // states
            PLAY_START = 3'b011, PLAY = 3'b100, GAME_OVER = 3'b101, PAUSING = 3'b110;
    
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
                    if (go) state_next <= PAUSING;
                    else state_next <= PLAY;
            end
            PAUSING: begin
                if (!go) state_next <= LEVEL_PAUSE;
                else state_next <= PAUSING;
            end
            default: state_next = LEVEL_SELECT;
        endcase
    end // state_table
    
    // State Registers
    always @(posedge clk)
    begin: state_FFs
        if(!resetn)
            state <= LEVEL_SELECT;
        else
            state <= state_next;
    end // state_FFS

    // Output logic
    assign load_level = (state == LOAD_LEVEL);
    assign level_pause = (state == LEVEL_PAUSE);
    assign play = (state == PLAY);
endmodule

// Controls what is being drawn
module animate_control(
    input load_level,
    input player_move,
    input ani_done,
    input resetn,
    input clk,
    output reg [2:0] ani_state
    );
    
    reg [2:0] state_next;
    localparam IDLE = 3'b000, DRAWPLAYER = 3'b001, LEVEL = 3'b010, ERASEPLAYER = 3'b011, 
            ERASEtoDRAW = 3'b100; // draw states
    
    always@(*)
    begin: state_table
        case (ani_state)
            IDLE: begin
                if (player_move) state_next <= ERASEPLAYER;
                else if (load_level) state_next <= LEVEL;
                else state_next <= IDLE;
            end
            DRAWPLAYER: begin
                if (ani_done) state_next <= IDLE;
                else state_next <= DRAWPLAYER;
            end
            ERASEPLAYER: begin
                if (ani_done) state_next <= ERASEtoDRAW;
                else state_next <= ERASEPLAYER;
            end
            LEVEL: begin
                if (ani_done) state_next <= IDLE;
                else state_next <= LEVEL;
            end
            default: state_next = IDLE;
        endcase
    end // state_table
    
    // State Registers
    always @(posedge clk)
    begin: state_FFs
        if(!resetn)
            ani_state <= IDLE;
        else
            ani_state <= state_next;
    end // state_FFS
endmodule

// Does the drawing
module datapath(
    input [7:0] playerX,
    input [6:0] playerY,
    input [7:0] enemyX,
    input [6:0] enemyY,
    input [2:0] ani_state,
    input resetn,
    input clk,
    output reg ani_done,
    output reg [7:0] x,
    output reg [6:0] y,
    output reg [2:0] colour,
    output reg drawEn
    );

    localparam IDLE = 3'b000, DRAWPLAYER = 3'b001, LEVEL = 3'b010, ERASEPLAYER = 3'b011; // draw states
    
    initial begin
        colour <= 3'b111;
        ani_done <= 0;
    end
    
    always@(posedge clk) begin
        if (!resetn) begin
            // TODO: clear the screen
        end
        else if (ani_state == LEVEL) begin
            // TODO: draw the level
            drawEn <= 1;
            x <= playerX;
            y <= playerY;
            // when finished drawing
            ani_done <= 1;
        end
        else if (ani_state == DRAWPLAYER) begin
            // TODO: draw the screen
            drawEn <= 1;
            colour = 3'b111;
            x <= playerX;
            y <= playerY;
            // when finished drawing
            ani_done <= 1;
        end
        else if (ani_state == ERASEPLAYER) begin
            // TODO: erase old screen
            drawEn <= 1;
            colour = 3'b000;
            //it should retain its old position at this point
            //x <= x;
            //y <= y;
            
            // when finished drawing
            ani_done <= 1;
        end
        else begin
            drawEn <= 0;
            ani_done <= 0;
        end
    end
endmodule
