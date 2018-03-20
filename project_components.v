`define SCREEN_W 8'd160
`define SCREEN_H 7'd120
`define PLAYER_SIZE 2'd3

module player_control(
    input left,
    input right,
    input play,
    input resetn,
    input clk,
    output reg move,
    output reg [7:0] playerX, // x and y for top left pixel of player
    output reg [6:0] playerY
    );
    
    localparam RATE_DIV = 28'd500000; // lower to move faster
    localparam START_X = 8'd80, START_Y = 7'd115;
    reg [27:0] counter;
    
    initial begin
        playerX <= START_X;
        playerY <= START_Y;
    end
    
    always@(posedge clk) begin
        if (!resetn) begin
            counter <= 0;
            move <= 0;
            playerX <= START_X;
            playerY <= START_Y;
        end
        
        if (play) begin     // control player through inputs
            if (left) begin
                if (counter == RATE_DIV) begin
                    if (playerX > 0)
                        playerX <= playerX - 1;
                    move <= 1;
                    counter <= 0;
                end
                else begin
                    counter <= counter + 1;
                    move <= 0;
                end
            end
            else if (right) begin
                if (counter == RATE_DIV) begin
                    if ((playerX + `PLAYER_SIZE - 1) < `SCREEN_W)
                        playerX <= playerX + 1;
                    move <= 1;
                    counter <= 0;
                end
                else begin
                    counter <= counter + 1;
                    move <= 0;
                end
            end
            else begin
                move <= 0;
                counter <= 0;
            end
        end
    end
endmodule

module enemy_control(
    input [2:0] size, // height of square enemy in pixels
    input [7:0] start_x,
    input [6:0] start_y,
    input [2:0] d_x, // slope d_y/d_x
    input [2:0] d_y,
    input leftwards, // direction of enemy when spawned
    input upwards,
    input [7:0] playerX,
    input [6:0] playerY,
    input load_level,
    input play,
    input resetn,
    input clk,
    output reg player_hit, // player collision
     output reg move,
    output reg [7:0] enemyX, // coordinates for the top left pixel of the enemy
    output reg [6:0] enemyY
    );
    
    localparam RATE_DIV = 28'd1000000; // lower to move faster
    reg [27:0] counter;
    reg left, up;
    
    always@(posedge clk) begin
        if (!resetn || load_level) begin
            enemyX <= start_x;
            enemyY <= start_y;
            counter <= 0;
            left <= leftwards;
            up <= upwards;
            player_hit <= 0;
        end
        if (play) begin
            if (counter == RATE_DIV) begin
                if (left) begin
                    if (enemyX - d_x <= 0) begin // hit left edge, change directions
                        enemyX <= 0;
                        left <= 0;
                    end else begin
                        enemyX <= enemyX - d_x;
                    end
                end else begin
                    if ((enemyX + size - 1) + d_x >= `SCREEN_W) begin // hit right edge
                        enemyX <= `SCREEN_W - size + 1;
                        left <= 1;
                    end else begin
                        enemyX <= enemyX + d_x;
                    end
                end
                if (up) begin
                    if (enemyY - d_y <= 0) begin // hit top edge
                        enemyY <= 0;
                        up <= 0;
                    end else begin
                        enemyY <= enemyY - d_y;
                    end
                end else begin
                    if ((enemyY + size - 1) + d_y >= `SCREEN_H) begin // hit bottom edge
                        enemyY <= `SCREEN_H - size + 1;
                        up <= 1;
                    end else begin
                        enemyY <= enemyY + d_y;
                    end
                end
                counter <= 0;
                     move <= 1;
            end else begin
                counter <= counter + 1;
                     move <= 0;
            end
            
            // collision with player
            if ((playerX <= (enemyX + size - 1) && enemyX <= (playerX + `PLAYER_SIZE - 1))
                && (playerY <= (enemyY + size - 1) && enemyY <= (playerY + `PLAYER_SIZE - 1))) begin
                player_hit <= 1;
            end
        end
    end
endmodule
