.text

## void
## collect_baskets(int max_baskets, Node *spot, Baskets *baskets) {
##     if (spot == NULL || baskets == NULL || spot->seen == 1) {
##         return;
##     }
##     spot->seen = 1;
##     for (int i = 0; i < spot->num_children && baskets->num_found < max_baskets;
##          i++) {
##         collect_baskets(max_baskets, spot->children[i], baskets);
##     }
##     if (baskets->num_found < max_baskets && get_num_carrots(spot) > 0) {
##         baskets->basket[baskets->num_found] = spot;
##         baskets->num_found++;
##     }
##     return;
## }
## 
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
## struct Baskets {
##     int num_found;
##     Node *basket[10];
## };

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

