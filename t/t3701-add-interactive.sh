	(echo d; echo 1) | git add -i >output &&
	(echo r; echo 1) | git add -i &&
	(echo d; echo 1) | git add -i >output &&
	(echo r; echo 1) | git add -i &&

	(echo e; echo a) | git add -p &&
	(echo e; echo n; echo d) | git add -p >output &&
	(echo e; echo n; echo d) | git add -p >output &&