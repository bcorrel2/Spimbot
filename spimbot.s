# syscall constants
PRINT_STRING = 4
PRINT_CHAR   = 11
PRINT_INT    = 1

# debug constants
PRINT_INT_ADDR   = 0xffff0080
PRINT_FLOAT_ADDR = 0xffff0084
PRINT_HEX_ADDR   = 0xffff0088

# spimbot constants
VELOCITY       = 0xffff0010
ANGLE          = 0xffff0014
ANGLE_CONTROL  = 0xffff0018
BOT_X          = 0xffff0020
BOT_Y          = 0xffff0024
OTHER_BOT_X    = 0xffff00a0
OTHER_BOT_Y    = 0xffff00a4
TIMER          = 0xffff001c
SCORES_REQUEST = 0xffff1018

# introduced in lab10
SEARCH_BUNNIES          = 0xffff0054
CATCH_BUNNY             = 0xffff0058
PUT_BUNNIES_IN_PLAYPEN  = 0xffff005c
PLAYPEN_LOCATION        = 0xffff0044

# introduced in labSpimbot
LOCK_PLAYPEN            = 0xffff0048
UNLOCK_PLAYPEN          = 0xffff004c
REQUEST_PUZZLE          = 0xffff00d0
SUBMIT_SOLUTION         = 0xffff00d4
NUM_BUNNIES_CARRIED     = 0xffff0050
NUM_CARROTS             = 0xffff0040
PLAYPEN_OTHER_LOCATION  = 0xffff00dc

# interrupt constants
BONK_MASK               = 0x1000
BONK_ACK                = 0xffff0060
TIMER_MASK              = 0x8000
TIMER_ACK               = 0xffff006c
BUNNY_MOVE_INT_MASK     = 0x400
BUNNY_MOVE_ACK          = 0xffff0020
PLAYPEN_UNLOCK_INT_MASK = 0x2000
PLAYPEN_UNLOCK_ACK      = 0xffff005c
EX_CARRY_LIMIT_INT_MASK = 0x4000
EX_CARRY_LIMIT_ACK      = 0xffff002c
REQUEST_PUZZLE_INT_MASK = 0x800
REQUEST_PUZZLE_ACK      = 0xffff00d8

.data
# data things go here

.text
main:
    # go wild
    # the world is your oyster :)

    # $s0 - playpen_x
    # $s1 - playpen_y
    # $s2 - playpen_enemy_x
    # $s3 - playpen_enemy_y

    # Friendly Playpen
    lw $s0, PLAYPEN_LOCATION
    lw $s1, PLAYPEN_LOCATION

    and $s0, $s0, 0xFFFF0000
    and $s1, $s1, 0x0000FFFF

    sra $s1, $s1, 16

    # Enemy Playpen
    lw $s2, PLAYPEN_OTHER_LOCATION
    lw $s3, PLAYPEN_OTHER_LOCATION

    and $s2, $s2, 0xFFFF0000
    and $s3, $s3, 0x0000FFFF

    sra $s3, $s3, 16

    # $t1: target_x
    # $t2: bot_x
    # $t3: target_y
    # $t4: bot_y

   # # # # # # # # # # #
   
   # @param: if on friendly playpen, place bunny.
   # else, if on enemy playpen, sabotage. 

   # # # # # # # # # # #

   j friendly_start

   friendly_start:
    	beq $t2, $s0, playpen_if
   	j enemy_start

   playpen_if:
	beq $t4, $s1, place_bunny
	j enemy_start

   enemy_start:
	beq $t2, $s2, enemy_playpen_if
	j main

   enemy_playpen_if:
	beq $t4, $s3, sabotage
	j main 

    # # # # # # # # # # #

    to_playpen:
	# @param: Set target to friendly playpen.
        move $t1, $s0
	move $t3, $s1


    place_bunny:
	# @param: determine number of bunnies carried.
	# unlock playpen, place bunnies, lock playpen. 
	lw $v0, NUM_BUNNIES_CARRIED
	sw $v0, UNLOCK_PLAYPEN
	sw $v0, PUT_BUNNIES_IN_PLAYPEN
	sw $v0, LOCK_PLAYPEN

    to_sabotage:
	# @param: Set target to enemy playpen.
	move $t1, $s2
	move $t3, $s3
	
    sabotage:
	# @param: unlock enemy playpen
	lw $v0, UNLOCK_PLAYPEN
	
    j   main

