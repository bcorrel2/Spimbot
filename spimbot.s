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
puzzle_data: .space 9804
baskets_data: .space 44
puzzlesolution:	.space 4
turns: .word 1 0 -1 0

.text
main:
	li $s8, 0 #emergency boolean

	sub	$sp, $sp, 4		#allocate mem
	lw	$t0, TIMER
	sw	$t0, 0($sp)	#store time
	li	$v1, 0			#carrot flag false
    
	# enable interrupts
	li	$t4, TIMER_MASK		# timer interrupt enable bit
	or	$t4, $t4, BONK_MASK	# bonk interrupt bit
	or	$t4, $t4, PLAYPEN_UNLOCK_INT_MASK	#playpen opened
	or	$t4, $t4, REQUEST_PUZZLE_INT_MASK	#puzzle ready
	or	$t4, $t4, 1				#global
	mtc0	$t4, $12			# set interrupt mask (Status register)

	# request timer interrupt
	lw	$t0, TIMER				# read current time
	add	$t0, $t0, 50			# add 50 to current time
	sw	$t0, TIMER				# request timer interrupt in 50 cycles

beginning:
	beq	$s8, 1, to_save			#if unlock interrupt, then save pen
	lw	$t0, NUM_CARROTS		#get carrots
	bge	$t0, 10, next			#only request a puzzle if carrots is less than 10
	la	$t0, puzzle_data		#request a puzzle
	sw	$t0, REQUEST_PUZZLE		# ^^
next:	
    la	$t0, bunnies_data
	sw	$t0, SEARCH_BUNNIES		#need to retrieve this after jal if necessary

	lw	$t9, NUM_BUNNIES_CARRIED #get bunnies carried
	bge	$t9, 7, deposit			#deposit bunnies in pen
moving:
	beq	$v1, 0, skip_puzzle		#skip puzzle if not ready
	li	$a0, 10					#max baskets = 10
	la	$a1, puzzle_data
	lw	$a1, 9800($a1)			#get k
	la	$a2, puzzle_data		#root node
	la	$a3, baskets_data
	sw	$0, 0($a3)				#store 0 for num_found
	jal	search_carrot
	sw	$v0, puzzlesolution		#store to mem
	la	$v0, puzzlesolution
	sw	$v0, SUBMIT_SOLUTION	#submit solution
	la	$t0, bunnies_data		#retrieve bunny data
	
skip_puzzle:
	lw	$t2, BOT_X				#get bot x
	lw	$t4, BOT_Y				#get bot y
	lw	$t8, TIMER				#current time
	lw	$t9, 0($sp)				#retrieve last sabotage time
	sub	$t8, $t8, $t9			#get time since sabotage
	ble	$t8, 1000000, continue_bunnies	#don't sabotage if too soon

	lw	$t5, PLAYPEN_OTHER_LOCATION	#load location
	srl	$t1, $t5, 16			#get x loc
	and	$t3, $t5, 0x0000ffff	#get y loc
	sub	$t8, $t2, $t1			#x diff from enemy pen
	sra	$t7, $t8, 31			#get signed bit
	xor	$t8, $t8, $t7			#invert bits
	sub	$t8, $t8, $t7			#get abs value of x diff
	sub	$t9, $t4, $t3			#y diff from enemy pen
	sra	$t7, $t9, 31			#get signed bit
	xor	$t9, $t9, $t7			#invert bits
	sub	$t9, $t9, $t7			#get abs value of y diff
	move $a0, $t8				#arg 0 = x diff
	move $a1, $t9				#arg 1 = y diff
	jal	euclidean_dist			#find euc dist
	ble	$v0, 150, sabotage		#go sabotage

continue_bunnies:
	la	$t0, bunnies_data		#could be messed up from sb_arc
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
	jal	euclidean_dist			#find euc dist
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
	j	beginning
deposit:
	lw	$t5, PLAYPEN_LOCATION	#load location
	srl	$t1, $t5, 16			#get x loc
	and	$t3, $t5, 0x0000ffff	#get y loc
	lw	$t2, BOT_X				#get bot x
	lw	$t4, BOT_Y				#get bot y
	sub	$t1, $t1, $t2			#x diff
	sub	$t3, $t3, $t4			#y diff
	bne	$t1, $0, move_to_pen	#check if at pen x
	bne	$t3, $0, move_to_pen	#check if at pen y
	j	give_bunnies
move_to_pen:
	move $a0, $t1				#arg0 = x diff
	move $a1, $t3				#arg1 = y diff
	jal	sb_arctan				#find angle
	sw	$v0, ANGLE				#set angle
	li	$t1, 1					#absolute direction
	sw	$t1, ANGLE_CONTROL		#change angle control	
	li	$t3, 10					#set speed
	sw	$t3, VELOCITY			#change speed
	j	deposit					#keep depositing
give_bunnies:
	li	$t1, 7					#deposit
	sw	$t1, PUT_BUNNIES_IN_PLAYPEN	#make a deposit at the bunny bank
	sw 	$v0, LOCK_PLAYPEN
	j	beginning
sabotage:
	beq	$s8, 1, to_save			#check for enemy sabotage
	lw	$t2, BOT_X				#get bot x
	lw	$t4, BOT_Y				#get bot y
	lw	$t5, PLAYPEN_OTHER_LOCATION	#load location
	srl	$t1, $t5, 16			#get x loc
	and	$t3, $t5, 0x0000ffff	#get y loc
	sub	$t8, $t1, $t2			#x diff from enemy pen
	sub	$t9, $t3, $t4			#y diff from enemy pen
	beq	$t8, $0, open_pen		#x are the same
	beq	$t9, $0, open_pen		#y are the same
	move $a0, $t8				#x diff
	move $a1, $t9				#y diff
	jal	sb_arctan				#get angle
	sw	$v0, ANGLE				#set angle
	li	$t1, 1					#absolute direction
	sw	$t1, ANGLE_CONTROL		#change angle control	
	li	$t3, 10					#set speed
	sw	$t3, VELOCITY			#change speed
	j 	sabotage
open_pen:
	sw	$v0, UNLOCK_PLAYPEN		#unlock pen
	lw	$t9, TIMER
	sw	$t9, 0($sp)				#log time unlocked
	j 	beginning

to_save:
	lw	$t5, PLAYPEN_LOCATION	#load location
	srl	$t1, $t5, 16			#get x loc
	and	$t3, $t5, 0x0000ffff	#get y loc
	lw	$t2, BOT_X				#get bot x
	lw	$t4, BOT_Y				#get bot y
	sub	$t1, $t1, $t2			#x diff
	sub	$t3, $t3, $t4			#y diff
	bne	$t1, $0, move_to_save	#check if at pen x
	bne	$t3, $0, move_to_save	#check if at pen y
	sw 	$v0, LOCK_PLAYPEN
	li	$s8, 0
	j	beginning
move_to_save:
	move $a0, $t1				#arg0 = x diff
	move $a1, $t3				#arg1 = y diff
	jal	sb_arctan				#find angle
	sw	$v0, ANGLE				#set angle
	li	$t1, 1					#absolute direction
	sw	$t1, ANGLE_CONTROL		#change angle control	
	li	$t3, 10					#set speed
	sw	$t3, VELOCITY			#change speed
	j	to_save
	
#--------------------------------------------------------------------- Interrupt handlers	
	
.kdata				# interrupt handler data (separated just for readability)
chunkIH:	.space 8	# space for two registers
non_intrpt_str:	.asciiz "Non-interrupt exception\n"
unhandled_str:	.asciiz "Unhandled interrupt type\n"


.ktext 0x80000180
interrupt_handler:
.set noat
	move	$k1, $at		# Save $at                               
.set at
	la	$k0, chunkIH
	sw	$a0, 0($k0)		# Get some free registers                  
	sw	$a1, 4($k0)		# by storing them to a global variable     

	mfc0	$k0, $13		# Get Cause register                       
	srl	$a0, $k0, 2                
	and	$a0, $a0, 0xf		# ExcCode field                            
	bne	$a0, 0, non_intrpt         

interrupt_dispatch:			# Interrupt:                             
	mfc0	$k0, $13		# Get Cause register, again                 
	beq	$k0, 0, done		# handled all outstanding interrupts     

	and	$a0, $k0, BONK_MASK	# is there a bonk interrupt?                
	bne	$a0, 0, bonk_interrupt   

	and	$a0, $k0, TIMER_MASK	# is there a timer interrupt?
	bne	$a0, 0, timer_interrupt

	# add dispatch for other interrupt types here.
	
	and	$a0, $k0, PLAYPEN_UNLOCK_INT_MASK	# is there a playpen unlocked interrupt?
	bne	$a0, 0, unlock_interrupt
	
	and	$a0, $k0, REQUEST_PUZZLE_INT_MASK	# is there a puzzle request interrupt?
	bne	$a0, 0, puzzle_interrupt

	li	$v0, PRINT_STRING	# Unhandled interrupt types
	la	$a0, unhandled_str
	syscall 
	j	done

unlock_interrupt:
	sw  	$a1, PLAYPEN_UNLOCK_ACK  # acknowledge interrupt
	li $s8, 1 #emergency boolean

	j 	interrupt_dispatch
	
puzzle_interrupt:
	sw	$a1, REQUEST_PUZZLE_ACK
	li	$v1, 1							#flag true
	j	interrupt_dispatch

bonk_interrupt:
      sw      $a1, 0xffff0060($zero)   # acknowledge interrupt

      li      $a1, 10                  #  ??
      lw      $a0, 0xffff001c($zero)   # what
      and     $a0, $a0, 1              # does
      bne     $a0, $zero, bonk_skip    # this 
      li      $a1, -10                 # code
      
bonk_skip:                             #  do 
      sw      $a1, 0xffff0010($zero)   #  ??  

      j       interrupt_dispatch       # see if other interrupts are waiting

timer_interrupt:
	sw	$a1, TIMER_ACK		# acknowledge interrupt

	li	$t8, 90			# ???
	sw	$t8, ANGLE		# ???
	sw	$zero, ANGLE_CONTROL	# ???

	lw	$v0, TIMER		# current time
	add	$v0, $v0, 50000  
	sw	$v0, TIMER		# request timer in 50000 cycles

	j	interrupt_dispatch	# see if other interrupts are waiting
      
non_intrpt:				# was some non-interrupt
	li	$v0, PRINT_STRING
	la	$a0, non_intrpt_str
	syscall				# print out an error message
	# fall through to done

done:
	la	$k0, chunkIH
	lw	$a0, 0($k0)		# Restore saved registers
	lw	$a1, 4($k0)
.set noat
	move	$at, $k1		# Restore $at
.set at 
	eret

.data
three:	.float	3.0
five:	.float	5.0
PI:	.float	3.141592
F180:	.float  180.0
	
.text

# -----------------------------------------------------------------------
# sb_arctan - computes the arctangent of y / x
# $a0 - x
# $a1 - y
# returns the arctangent
# -----------------------------------------------------------------------
.globl sb_arctan
sb_arctan:
	li	$v0, 0		# angle = 0;

	abs	$t0, $a0	# get absolute values
	abs	$t1, $a1
	ble	$t1, $t0, no_TURN_90	  

	## if (abs(y) > abs(x)) { rotate 90 degrees }
	move	$t0, $a1	# int temp = y;
	neg	$a1, $a0	# y = -x;      
	move	$a0, $t0	# x = temp;    
	li	$v0, 90		# angle = 90;  

no_TURN_90:
	bgez	$a0, pos_x 	# skip if (x >= 0)

	## if (x < 0) 
	add	$v0, $v0, 180	# angle += 180;

pos_x:
	mtc1	$a0, $f0
	mtc1	$a1, $f1
	cvt.s.w $f0, $f0	# convert from ints to floats
	cvt.s.w $f1, $f1
	
	div.s	$f0, $f1, $f0	# float v = (float) y / (float) x;

	mul.s	$f1, $f0, $f0	# v^^2
	mul.s	$f2, $f1, $f0	# v^^3
	l.s	$f3, three	# load 3.0
	div.s 	$f3, $f2, $f3	# v^^3/3
	sub.s	$f6, $f0, $f3	# v - v^^3/3

	mul.s	$f4, $f1, $f2	# v^^5
	l.s	$f5, five	# load 5.0
	div.s 	$f5, $f4, $f5	# v^^5/5
	add.s	$f6, $f6, $f5	# value = v - v^^3/3 + v^^5/5

	l.s	$f8, PI		# load PI
	div.s	$f6, $f6, $f8	# value / PI
	l.s	$f7, F180	# load 180.0
	mul.s	$f6, $f6, $f7	# 180.0 * value / PI

	cvt.w.s $f6, $f6	# convert "delta" back to integer
	mfc1	$t0, $f6
	add	$v0, $v0, $t0	# angle += delta

	jr 	$ra
	

# -----------------------------------------------------------------------
# euclidean_dist - computes sqrt(x^2 + y^2)
# $a0 - x
# $a1 - y
# returns the distance
# -----------------------------------------------------------------------

.globl euclidean_dist
euclidean_dist:
	mul	$a0, $a0, $a0	# x^2
	mul	$a1, $a1, $a1	# y^2
	add	$v0, $a0, $a1	# x^2 + y^2
	mtc1	$v0, $f0
	cvt.s.w	$f0, $f0	# float(x^2 + y^2)
	sqrt.s	$f0, $f0	# sqrt(x^2 + y^2)
	cvt.w.s	$f0, $f0	# int(sqrt(...))
	mfc1	$v0, $f0
	jr	$ra


.globl search_carrot
search_carrot:
	move	$v0, $0			# set return value to 0 early
	beq	$a2, 0, sc_ret		# if (root == NULL), return 0
	beq	$a3, 0, sc_ret		# if (baskets == NULL), return 0

	sub	$sp, $sp, 12
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)

	move	$s0, $a1		# $s0 = int k
	move	$s1, $a3		# $s1 = Baskets *baskets

	sw	$0, 0($a3)		# baskets->num_found = 0

	move	$t0, $0			# $t0 = int i = 0
sc_for:
	bge	$t0, $a0, sc_done	# if (i >= max_baskets), done

	mul	$t1, $t0, 4
	add	$t1, $t1, $a3
	sw	$t0, 4($t1)		# baskets->basket[i] = NULL

	add	$t0, $t0, 1		# i++
	j	sc_for


sc_done:
	move	$a1, $a2
	move	$a2, $a3
	jal	collect_baskets		# collect_baskets(max_baskets, root, baskets)

	move	$a0, $s0
	move	$a1, $s1
	jal	pick_best_k_baskets	# pick_best_k_baskets(k, baskets)

	move	$a0, $s0
	move	$a1, $s1

	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	add	$sp, $sp, 12

	j	get_secret_id		# get_secret_id(k, baskets), tail call

sc_ret:
	jr	$ra

.globl collect_baskets
collect_baskets:
	beq	$a1, 0, cb_ret		# if (spot == NULL), return
	beq	$a2, 0, cb_ret		# if (baskets == NULL), return
	lb	$t0, 0($a1)
	beq	$t0, 1, cb_ret		# if (spot->seen == 1), return

	li	$t0, 1
	sb	$t0, 0($a1)		# spot->seen = 1

	sub	$sp, $sp, 20
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)

	move	$s0, $a0		# $s0 = int max_baskets
	move	$s1, $a1		# $s1 = Node *spot
	move	$s2, $a2		# $s2 = Baskets *baskets

	move	$s3, $0			# $s3 = int i = 0
cb_for:
	lw	$t0, 20($s1)		# spot->num_children
	bge	$s3, $t0, cb_done	# if (i >= spot->num_children), done
	lw	$t0, 0($s2)		# baskets->num_found
	bge	$t0, $s0, cb_done	# if (baskets->num_found >= max_baskets), done

	move	$a0, $s0
	mul	$a1, $s3, 4
	add	$a1, $a1, $s1
	lw	$a1, 24($a1)		# spot->children[i]
	move	$a2, $s2
	jal	collect_baskets		# collect_baskets(max_baskets, spot->children[i], baskets)

	add	$s3, $s3, 1		# i++
	j	cb_for


cb_done:
	lw	$t0, 0($s2)		# baskets->num_found
	bge	$t0, $s0, cb_return	# if (baskets->num_found >= max_baskets), return

	move	$a0, $s1
	jal	get_num_carrots
	ble	$v0, 0, cb_return 	# if (get_num_carrots(spot) <= 0), return

	lw	$t0, 0($s2)		# baskets->num_found
	mul	$t1, $t0, 4
	add	$t1, $t1, $s2
	sw	$s1, 4($t1)		# baskets->basket[baskets->num_found] = spot

	add	$t0, $t0, 1
	sw	$t0, 0($s2)		# baskets->num_found++

cb_return:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	add	$sp, $sp, 20

cb_ret:
	jr	$ra

.globl get_num_carrots
get_num_carrots:
	bne	$a0, 0, gnc_do		# if (spot != NULL), continue
	move	$v0, $0			# return 0
	jr	$ra

gnc_do:
	lw	$t0, 8($a0)		# spot->dirt
	xor	$t0, $t0, 0x00ff00ff	# $t0 = unsigned int dig = spot->dirt ^ 0x00ff00ff

	and	$t1, $t0, 0xffffff 	# dig & 0xffffff
	sll	$t1, $t1, 8		# (dig & 0xffffff) << 8

	and	$t2, $t0, 0xff000000 	# dig & 0xff00aadi0000
	srl	$t2, $t2, 24		# (dig & 0xff000000) >> 24

	or	$t0, $t1, $t2		# dig = ((dig & 0xffffff) << 8) | ((dig & 0xff000000) >> 24)

	lw	$v0, 4($a0)		# spot->basket
	xor	$v0, $v0, $t0		# return spot->basket ^ dig
	jr	$ra

.globl pick_best_k_baskets
pick_best_k_baskets:
	bne	$a1, 0, pbkb_do
	jr	$ra

pbkb_do:
	sub	$sp, $sp, 32
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$s5, 24($sp)
	sw	$s6, 28($sp)

	move	$s0, $a0			# $s0 = int k
	move	$s1, $a1			# $s1 = Baskets *baskets

	li	$s2, 0				# $s2 = int i = 0
pbkb_for_i:
	bge	$s2, $s0, pbkb_done		# if (i >= k), done

	lw	$s3, 0($s1)
	sub	$s3, $s3, 1			# $s3 = int j = baskets->num_found - 1
pbkb_for_j:
	ble	$s3, $s2, pbkb_for_j_done	# if (j <= i), done

	sub	$s5, $s3, 1
	mul	$s5, $s5, 4
	add	$s5, $s5, $s1
	lw	$a0, 4($s5)			# baskets->basket[j-1]
	jal	get_num_carrots			# get_num_carrots(baskets->basket[j-1])
	move	$s4, $v0

	mul	$s6, $s3, 4
	add	$s6, $s6, $s1
	lw	$a0, 4($s6)			# baskets->basket[j]
	jal	get_num_carrots			# get_num_carrots(baskets->basket[j])

	bge	$s4, $v0, pbkb_for_j_cont	# if (get_num_carrots(baskets->basket[j-1]) >= get_num_carrots(baskets->basket[j])), skip

	## This is very inefficient in MIPS. Can you think of a better way?

	## We're changing the _values_ of the array elements, so we don't need to
	## recompute addresses every time, and can reuse them from earlier.

	lw	$t0, 4($s6)			# baskets->basket[j]
	lw	$t1, 4($s5)			# baskets->basket[j-1]
	xor	$t2, $t0, $t1			# baskets->basket[j] ^ baskets->basket[j-1]
	sw	$t2, 4($s6)			# baskets->basket[j] = baskets->basket[j] ^ baskets->basket[j-1]

	lw	$t0, 4($s6)			# baskets->basket[j]
	lw	$t1, 4($s5)			# baskets->basket[j-1]
	xor	$t2, $t0, $t1			# baskets->basket[j] ^ baskets->basket[j-1]
	sw	$t2, 4($s5)			# baskets->basket[j-1] = baskets->basket[j] ^ baskets->basket[j-1]

	lw	$t0, 4($s6)			# baskets->basket[j]
	lw	$t1, 4($s5)			# baskets->basket[j-1]
	xor	$t2, $t0, $t1			# baskets->basket[j] ^ baskets->basket[j-1]
	sw	$t2, 4($s6)			# baskets->basket[j] = baskets->basket[j] ^ baskets->basket[j-1]

pbkb_for_j_cont:
	sub	$s3, $s3, 1			# j--
	j	pbkb_for_j

pbkb_for_j_done:
	add	$s2, $s2, 1			# i++
	j	pbkb_for_i

pbkb_done:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	lw	$s5, 24($sp)
	lw	$s6, 28($sp)
	add	$sp, $sp, 32
	jr	$ra

.globl get_secret_id
get_secret_id:
	bne	$a1, 0, gsi_do		# if (baskets != NULL), continue
	move	$v0, $0			# return 0
	jr	$ra

gsi_do:
	sub	$sp, $sp, 20
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)

	move	$s0, $a0		# $s0 = int k
	move	$s1, $a1		# $s1 = Baskets *baskets
	move	$s2, $0			# $s2 = int secret_id = 0

	move	$s3, $0			# $s3 = int i = 0
gsi_for:
	bge	$s3, $s0, gsi_return	# if (i >= k), done

	mul	$t0, $s3, 4
	add	$t0, $t0, $s1
	lw	$t0, 4($t0)			# baskets->basket[i]

	lw	$a0, 16($t0)		# baskets->basket[i]->identity
	lw	$a1, 12($t0)		# baskets->basket[i]->id_size
	jal	calculate_identity	# calculate_identity(baskets->basket[i]->identity, baskets->basket[i]->id_size)

	addu	$s2, $s2, $v0		# secret_it += ...

	add	$s3, $s3, 1		# i++
	j	gsi_for

gsi_return:
	move	$v0, $s2		# return secret_id

	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	add	$sp, $sp, 20
	jr	$ra

.globl calculate_identity
calculate_identity:
	sub	$sp, $sp, 36
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$s5, 24($sp)
	sw	$s6, 28($sp)
	sw	$s7, 32($sp)

	move	$s0, $a0		# $s0 = int *v
	move	$s1, $a1		# $s1 = int size

	move	$s2, $s1		# $s2 = int dist = size
	move	$s3, $0			# $s3 = int total = 0
	li	$s4, -1			# $s4 = int idx = -1

	sw	$s1, turns+4		# turns[1] = size
	mul	$t0, $s1, $s4		# -size
	sw	$t0, turns+12		# turns[3] = -size

ci_while:
	ble	$s2, 0, ci_done		# if (dist <= 0), done

	li	$s5, 0			# $s5 = int i = 0
ci_for_i:
	bge	$s5, 4, ci_while 	# if (i >= 4), done

	li	$s6, 0			# $s6 = int j = 0
ci_for_j:
	bge	$s6, $s2, ci_for_j_done # if (j >= dist), dine

	la	$t1, turns
	mul	$t0, $s5, 4
	add	$t0, $t0, $t1		# &turns[i]
	lw	$t0, 0($t0)		# turns[i]
	add	$s4, $s4, $t0		# idx = idx + turns[i]

	move	$a0, $s3		# total

	mul	$s7, $s4, 4
	add	$s7, $s7, $s0		# &v[idx]
	lw	$a1, 0($s7)		# v[idx]

	jal	accumulate		# accumulate(total, v[idx])
	move	$s3, $v0		# total = accumulate(total, v[idx])
	sw	$s3, 0($s7)		# v[idx] = total

	add	$s6, $s6, 1		# j++
	j	ci_for_j

ci_for_j_done:
	rem	$t0, $s5, 2		# i % 2
	bne	$t0, 0, ci_skip		# if (i % 2 != 0), skip
	sub	$s2, $s2, 1		# dist--

ci_skip:
	add	$s5, $s5, 1		# i++
	j	ci_for_i

ci_done:
	move	$a0, $s0		# v
	mul	$a1, $s1, $s1		# size * size
	jal	twisted_sum_array	# twisted_sum_array(v, size * size)

	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	lw	$s5, 24($sp)
	lw	$s6, 28($sp)
	lw	$s7, 32($sp)
	add	$sp, $sp, 36
	jr	$ra

.globl accumulate
accumulate:
	sub	$sp, $sp, 12
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)

	move	$s0, $a0
	move	$s1, $a1

	jal	max_conts_bits_in_common
	blt	$v0, 2, a_dp
	or	$v0, $s0, $s1
	j	a_ret

a_dp:
	move	$a0, $s1
	jal	detect_parity
	bne	$v0, 0, a_mul
	addu	$v0, $s0, $s1
	j	a_ret

a_mul:
	mul	$v0, $s0, $s1

a_ret:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	add	$sp, $sp, 12
	jr	$ra

.globl detect_parity
detect_parity:
	li	$t1, 0			# $t1 = int bits_counted = 0
	li	$v0, 1			# $v0 = int return_value = 1

	li	$t0, 0			# $t0 = int i = 0
dp_for:
	bge	$t0, 32, dp_done	# if (i >= INT_SIZE), done

	sra	$t3, $a0, $t0		# number >> i
	and	$t3, $t3, 1		# $t3 = int bit = (number >> i) & 1

	beq	$t3, 0, dp_skip		# if (bit == 0), skip
	add	$t1, $t1, 1		# bits_counted++

dp_skip:
	add	$t0, $t0, 1		# i++
	j	dp_for

dp_done:
	rem	$t3, $t1, 2		# bits_counted % 2
	beq	$t3, 0, dp_ret		# if (bits_counted % 2 == 0), skip
	li	$v0, 0			# return_value = 0

dp_ret:
	jr	$ra			# $v0 is already return_value

.globl max_conts_bits_in_common
max_conts_bits_in_common:
	li	$t1, 0			# $t1 = int bits_seen = 0
	li	$v0, 0			# $v0 = int max_seen = 0
	and	$t2, $a0, $a1		# $t2 = int c = a & b

	li	$t0, 0			# $t0 = int i = 0
mcbic_for:
	bge	$t0, 32, mcbic_done	# if (i >= INT_SIZE), done

	sra	$t3, $t2, $t0		# c >> i
	and	$t3, $t3, 1		# $t3 = int bit = (c >> i) & 1

	beq	$t3, 0, mcbic_else 	# if (bit == 0), else
	add	$t1, $t1, 1		# bits_seen++
	j	mcbic_cont

mcbic_else:
	ble	$t1, $v0, mcbic_skip 	# if (bit_seen <= max_seen), skip
	move	$v0, $t1		# max_seen = bits_seen

mcbic_skip:
	li	$t1, 0			# bits_seen = 0

mcbic_cont:
	add	$t0, $t0, 1		# i++
	j	mcbic_for

mcbic_done:
	ble	$t1, $v0, mcbic_ret 	# if (bits_seen <= max_seen), skip
	move	$v0, $t1		# max_seen = bits_seen

mcbic_ret:
	jr	$ra			# $v0 is already max_seen

.globl twisted_sum_array
twisted_sum_array:
	li	$v0, 0			# $v0 = int sum = 0

	li	$t0, 0			# $t0 = int i = 0
tsa_for:
	bge	$t0, $a1, tsa_done	# if (i >= length), done

	sub	$t1, $a1, 1		# length - 1
	sub	$t1, $t1, $t0		# length - 1 - i
	mul	$t1, $t1, 4
	add	$t1, $t1, $a0		# &v[length - 1 - i]
	lw	$t2, 0($t1)		# v[length - 1 - i]
	and	$t2, $t2, 1		# v[length - 1 - i] & 1

	beq	$t2, 0, tsa_skip	# if (v[length - 1 - i] & 1 == 0), skip
	sra	$v0, $v0, 1		# sum >>= 1

tsa_skip:
	mul	$t1, $t0, 4
	add	$t1, $t1, $a0		# &v[i]
	lw	$t2, 0($t1)		# v[i]
	addu	$v0, $v0, $t2		# sum += v[i]

	add	$t0, $t0, 1		# i++
	j	tsa_for

tsa_done:
	jr	$ra			# $v0 is already sum
