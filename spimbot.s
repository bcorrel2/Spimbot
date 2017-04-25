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
.align 2
bunnies_data: .space 484

.text
main:
    la	$t0, bunnies_data
	sw	$t0, SEARCH_BUNNIES		#need to retrieve this after jal if necessary	
moving:
	lw	$t2, BOT_X				#get bot x
	lw	$t4, BOT_Y				#get bot y
	li	$t8, 0					#bunny offset
	li	$t9, 9000000			#super high value
	add	$t1, $t0, 4				#bunny x addr
	add	$t3, $t0, 8				#bunny y addr
	li	$t0, 0					#curr bunny offset
closest:
	bge	$t0, 20, start			#start going to bunny
	lw	$t5, 0($t1)				#bunny x
	lw	$t6, 0($t3)				#bunny y
	sub	$t5, $t5, $t2			#get x diff
	sra	$t7, $t5, 31			#get signed bit
	xor	$t5, $t5, $t7			#invert bits
	sub	$t5, $t5, $t7			#get abs value of x diff
	sub	$t6, $t6, $t4			#get y diff
	sra	$t7, $t6, 31			#get signed bit
	xor	$t6, $t6, $t7			#invert bits
	sub	$t6, $t6, $t7			#get abs value of y diff
	move $a0, $t5				#arg 0 = x diff
	move $a1, $t6				#arg 1 = y diff
	jal	euclidean_dist			#find euc dist;
	bge	$v0, $t9, skip			#if euc dist is greater than best, skip it
	move $t9, $v0				#update best value
	move $t8, $t0				#bunny offset
skip:
	add	$t0, $t0, 1				#increment bunny offset
	add	$t1, $t1, 16			#next bunny x
	add	$t3, $t3, 16			#next bunny y
	j closest					#keep searching
start:
	la	$t0, bunnies_data		#retrieve bunny address
	mul	$t5, $t8, 16			#bunny offset
	add	$t5, $t5, $t0			#bunny addr
	lw	$t1, 4($t5)				#closest bunny x
	lw	$t3, 8($t5)				#closest bunny y
	sub	$t1, $t1, $t2			#x diff
	sub	$t3, $t3, $t4			#y diff
	bne	$t1, $0, control		#go to control if x coords are diff
	bne	$t3, $0, control		#same for y
	j	catch					#catch the bunny
control:
	move $a0, $t1				#arg0 = x diff
	move $a1, $t3				#arg1 = y diff
	jal	sb_arctan				#find angle
	sw	$v0, ANGLE				#set angle
	li	$t1, 1					#absolute direction
	sw	$t1, ANGLE_CONTROL		#change angle control	
	li	$t3, 10					#set speed
	sw	$t3, VELOCITY			#change speed
	la	$t0, bunnies_data		#retrieve bunny address
	j	moving					#continue until bunny found
catch:		
	li	$t5, 0					#gonna catch a bunny
	sw	$t5, CATCH_BUNNY		#call catch bunny
	j	main
