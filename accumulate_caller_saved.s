.text

## int
## accumulate(int total, int value) {
##     if (max_conts_bits_in_common(total, value) >= 2) {
##         total = total | value;
##     } else if (detect_parity(value) == 0) {
##         total = total + value;
##     } else {
##         total = total * value;
##     }
##     return total;
## }

.globl accumulate
accumulate:
	sub	$sp, $sp, 12
	sw	$ra, 0($sp)
	sw	$a0, 4($sp)
	sw	$a1, 8($sp)

	jal	max_conts_bits_in_common
	blt	$v0, 2, a_dp
	lw	$v0, 4($sp)
	lw	$t0, 8($sp)
	or	$v0, $v0, $t0
	j	a_ret

a_dp:
	lw	$a0, 8($sp)
	jal	detect_parity
	bne	$v0, 0, a_mul
	lw	$v0, 4($sp)
	lw	$t0, 8($sp)
	add	$v0, $v0, $t0
	j	a_ret

a_mul:
	lw	$v0, 4($sp)
	lw	$t0, 8($sp)
	mul	$v0, $v0, $t0

a_ret:
	lw	$ra, 0($sp)
	add	$sp, $sp, 12
	jr	$ra
