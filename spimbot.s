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

.text
main:
	li	$v1, 0			#carrot flag false

    li $s5, 0 #emergency boolean
    
	# Friendly Playpen
    lw $s0, PLAYPEN_LOCATION
    lw $s1, PLAYPEN_LOCATION

    and $s0, $s0, 0xFFFF0000
    and $s1, $s1, 0x0000FFFF


    sra $s0, $s0, 16

    
    # Enemy Playpen
    lw $s2, PLAYPEN_OTHER_LOCATION
    lw $s3, PLAYPEN_OTHER_LOCATION

    and $s2, $s2, 0xFFFF0000
    and $s3, $s3, 0x0000FFFF


  sra $s2, $s2, 16

	lw	$s4, TIMER		#get timer

    
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
	lw	$a2, puzzle_data		#root node
	la	$v0, baskets_data
	sw	$0, 0($v0)				#store 0 for num_found
	lw	$a3, baskets_data		#get baskets
	jal	search_carrot
	sw	$v0, puzzlesolution		#store to mem
	la	$v0, puzzlesolution
	sw	$v0, SUBMIT_SOLUTION	#submit solution
	la	$t0, bunnies_data		#retrieve bunny data
	
skip_puzzle:
	lw	$t2, BOT_X				#get bot x
	lw	$t4, BOT_Y				#get bot y
	lw	$t8, TIMER				#current time
	sub	$t8, $t8, $s4			#get time since sabotage
	ble	$t8, 1000000, continue_bunnies	#don't sabotage if too soon

	sub	$t8, $t2, $s2			#x diff from enemy pen
	sra	$t7, $t8, 31			#get signed bit
	xor	$t8, $t8, $t7			#invert bits
	sub	$t8, $t8, $t7			#get abs value of x diff
	sub	$t9, $t4, $s3			#y diff from enemy pen
	sra	$t7, $t9, 31			#get signed bit
	xor	$t9, $t9, $t7			#invert bits
	sub	$t9, $t9, $t7			#get abs value of y diff
	move $a0, $t8				#arg 0 = x diff
	move $a1, $t9				#arg 1 = y diff
	jal	euclidean_dist			#find euc dist
	ble	$v0, 150, sabotage		#go sabotage

continue_bunnies:
	la	$t0, bunnies_data		#could be messed up from sb_arc

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
	lw	$t2, BOT_X				#get bot x
	lw	$t4, BOT_Y				#get bot y
	sub	$t8, $s2, $t2			#x diff from enemy pen
	sub	$t9, $s3, $t4			#y diff from enemy pen
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
	lw	$s4, TIMER				#log time unlocked
	j 	beginning
	
to_sabotage:
	      # @param: Set target to enemy playpen.
	      beq  $s5, 1, to_save
	      move $t1, $s2
	      move $t3, $s3
	      lw      $t2, BOT_X                            #get bot x
        lw      $t4, BOT_Y                      #get bot y
        sub     $t1, $t1, $t2                   #x diff
        sub     $t3, $t3, $t4                   #y diff
        bne     $t1, $0, move_to_sabotage    #check if at enemy pen x
        bne     $t3, $0, move_to_sabotage    #check if at enemy pen y
        j       nsabotage

move_to_sabotage:
	      move $a0, $t1                           #arg0 = x diff
        move $a1, $t3                           #arg1 = y diff
        jal     sb_arctan                               #find angle
        sw      $v0, ANGLE                              #set angle
        li      $t1, 1                                  #absolute direction
        sw      $t1, ANGLE_CONTROL              #change angle control   
        li      $t3, 10                                 #set speed
        sw      $t3, VELOCITY                   #change speed
        j       to_sabotage   
	
nsabotage:
	# @param: unlock enemy playpen
	lw $v0, UNLOCK_PLAYPEN
	j beginning

to_save:
	move    $t1, $s2
        move    $t3, $s3
        lw      $t2, BOT_X          #get bot x
        lw      $t4, BOT_Y          #get bot y
        sub     $t1, $t1, $t2       #x diff
        sub     $t3, $t3, $t4       #y diff
        bne     $t1, $0, move_to_save    #check if at pen x
        bne     $t3, $0, move_to_save    #check if at pen y
        j       save

move_to_save:
	move $a0, $t1                           #arg0 = x diff
        move $a1, $t3                           #arg1 = y diff
        jal     sb_arctan                       #find angle
        sw      $v0, ANGLE                      #set angle
        li      $t1, 1                          #absolute direction
        sw      $t1, ANGLE_CONTROL              #change angle control   
        li      $t3, 10                         #set speed
        sw      $t3, VELOCITY                   #change speed
        j       to_save                         #keep moving

save:
	sw $v0, LOCK_PLAYPEN			#lock pen
	li $s5, 0				#emergency boolean
	j to_sabotage
>>>>>>> master
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
	li 	$s5, 1 #emergency boolean
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
