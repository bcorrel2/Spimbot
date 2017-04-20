.text

## int
## search_carrot(int max_baskets, int k, Node *root, Baskets *baskets) {
##     if (root == NULL || baskets == NULL) {
##         return 0;
##     }
##     baskets->num_found = 0;
##     for (int i = 0; i < max_baskets; i++) {
##         baskets->basket[i] = NULL;
##     }
##     collect_baskets(max_baskets, root, baskets);
##     pick_best_k_baskets(k, baskets);
##     return get_secret_id(k, baskets);
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
