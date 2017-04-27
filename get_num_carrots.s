.text

## struct Node {
##     char seen;
##     int basket;
##     int dirt;
##     int id_size;
##     int *identity;
##     int num_children;
##     Node *children[4];
## };
##
## int
## get_num_carrots(Node *spot) {
##     if (spot == NULL) {
##         return 0;
##     }
##     // Inverts the first and third byte.
##     unsigned int dig = spot->dirt ^ 0x00ff00ff;
##     // Circular shifts the bytes left one.
##     dig = ((dig & 0xffffff) << 8) | ((dig & 0xff000000) >> 24);
##     return spot->basket ^ dig;
## }

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
