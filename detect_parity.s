.text

## int
## detect_parity(int number) {
##     int bits_counted = 0;
##     int return_value = 1;
##     for (int i = 0; i < INT_SIZE; i++) {
##         int bit = (number >> i) & 1;
##         // zero is false, anything else is true
##         if (bit) { 
##             bits_counted++;
##         }
##     }
##     if (bits_counted % 2 != 0) {
##         return_value = 0;
##     }
##     return return_value;
## }

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
