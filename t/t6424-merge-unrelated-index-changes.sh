#!/bin/sh

test_description="merges with unrelated index changes"

. ./test-lib.sh

# Testcase for some simple merges
#   A
#   o-------o B
#    \
#     \-----o C
#      \
#       \---o D
#        \
#         \-o E
#          \
#           o F
#   Commit A: some file a
#   Commit B: adds file b, modifies end of a
#   Commit C: adds file c
#   Commit D: adds file d, modifies beginning of a
#   Commit E: renames a->subdir/a, adds subdir/e
#   Commit F: empty commit

test_expect_success 'setup trivial merges' '
	test_seq 1 10 >a &&
	git add a &&
	test_tick && git commit -m A &&

	git branch A &&
	git branch B &&
	git branch C &&
	git branch D &&
	git branch E &&
	git branch F &&

	git checkout B &&
	echo b >b &&
	echo 11 >>a &&
	git add a b &&
	test_tick && git commit -m B &&

	git checkout C &&
	echo c >c &&
	git add c &&
	test_tick && git commit -m C &&

	git checkout D &&
	test_seq 2 10 >a &&
	echo d >d &&
	git add a d &&
	test_tick && git commit -m D &&

	git checkout E &&
	mkdir subdir &&
	git mv a subdir/a &&
	echo e >subdir/e &&
	git add subdir &&
	test_tick && git commit -m E &&

	git checkout F &&
	test_tick && git commit --allow-empty -m F
'

test_expect_success 'ff update' '
	git reset --hard &&
	git checkout A^0 &&

	touch random_file && git add random_file &&

	git merge E^0 &&

	test_must_fail git rev-parse HEAD:random_file &&
	test "$(git diff --name-only --cached E)" = "random_file" &&
	test_path_is_file random_file &&
	git rev-parse --verify :random_file
'

test_expect_success 'ff update, important file modified' '
	git reset --hard &&
	git checkout A^0 &&

	mkdir subdir &&
	touch subdir/e &&
	git add subdir/e &&

	test_must_fail git merge E^0 &&
	test_path_is_file subdir/e &&
	git rev-parse --verify :subdir/e &&
	test_path_is_missing .git/MERGE_HEAD
'

test_expect_success 'resolve, trivial' '
	git reset --hard &&
	git checkout B^0 &&

	touch random_file && git add random_file &&

	test_must_fail git merge -s resolve C^0 &&
	test_path_is_file random_file &&
	git rev-parse --verify :random_file &&
	test_path_is_missing .git/MERGE_HEAD
'

test_expect_success 'resolve, non-trivial' '
	git reset --hard &&
	git checkout B^0 &&

	touch random_file && git add random_file &&

	test_must_fail git merge -s resolve D^0 &&
	test_path_is_file random_file &&
	git rev-parse --verify :random_file &&
	test_path_is_missing .git/MERGE_HEAD
'

test_expect_success 'recursive' '
	git reset --hard &&
	git checkout B^0 &&

	touch random_file && git add random_file &&

	test_must_fail git merge -s recursive C^0 &&
	test_path_is_file random_file &&
	git rev-parse --verify :random_file &&
	test_path_is_missing .git/MERGE_HEAD
'

test_expect_success 'recursive, when merge branch matches merge base' '
	git reset --hard &&
	git checkout B^0 &&

	touch random_file && git add random_file &&

	test_must_fail git merge -s recursive F^0 &&
	test_path_is_missing .git/MERGE_HEAD
'

test_expect_success 'merge-recursive, when index==head but head!=HEAD' '
	git reset --hard &&
	git checkout C^0 &&

	# Make index match B
	git diff C B -- | git apply --cached &&
	test_when_finished "git clean -fd" &&  # Do not leave untracked around
	# Merge B & F, with B as "head"
	git merge-recursive A -- B F > out &&
	test_i18ngrep "Already up to date" out
'

test_expect_success 'recursive, when file has staged changes not matching HEAD nor what a merge would give' '
	git reset --hard &&
	git checkout B^0 &&

	mkdir subdir &&
	test_seq 1 10 >subdir/a &&
	git add subdir/a &&
	git rev-parse --verify :subdir/a >expect &&

	# We have staged changes; merge should error out
	test_must_fail git merge -s recursive E^0 2>err &&
	git rev-parse --verify :subdir/a >actual &&
	test_cmp expect actual &&
	test_i18ngrep "changes to the following files would be overwritten" err
'

test_expect_success 'recursive, when file has staged changes matching what a merge would give' '
	git reset --hard &&
	git checkout B^0 &&

	mkdir subdir &&
	test_seq 1 11 >subdir/a &&
	git add subdir/a &&
	git rev-parse --verify :subdir/a >expect &&

	# We have staged changes; merge should error out
	test_must_fail git merge -s recursive E^0 2>err &&
	git rev-parse --verify :subdir/a >actual &&
	test_cmp expect actual &&
	test_i18ngrep "changes to the following files would be overwritten" err
'

test_expect_success 'octopus, unrelated file touched' '
	git reset --hard &&
	git checkout B^0 &&

	touch random_file && git add random_file &&

	test_must_fail git merge C^0 D^0 &&
	test_path_is_missing .git/MERGE_HEAD &&
	git rev-parse --verify :random_file &&
	test_path_exists random_file
'

test_expect_success 'octopus, related file removed' '
	git reset --hard &&
	git checkout B^0 &&

	git rm b &&

	test_must_fail git merge C^0 D^0 &&
	test_path_is_missing b &&
	test_must_fail git rev-parse --verify :b &&
	test_path_is_missing .git/MERGE_HEAD
'

test_expect_success 'octopus, related file modified' '
	git reset --hard &&
	git checkout B^0 &&

	echo 12 >>a && git add a &&
	git rev-parse --verify :a >expect &&

	test_must_fail git merge C^0 D^0 &&
	test_path_is_file a &&
	git rev-parse --verify :a >actual &&
	test_cmp expect actual &&
	test_path_is_missing .git/MERGE_HEAD
'

test_expect_success 'ours' '
	git reset --hard &&
	git checkout B^0 &&

	touch random_file && git add random_file &&

	test_must_fail git merge -s ours C^0 &&
	test_path_is_file random_file &&
	git rev-parse --verify :random_file &&
	test_path_is_missing .git/MERGE_HEAD
'

test_expect_success 'subtree' '
	git reset --hard &&
	git checkout B^0 &&

	touch random_file && git add random_file &&

	test_must_fail git merge -s subtree E^0 &&
	test_path_is_file random_file &&
	git rev-parse --verify :random_file &&
	test_path_is_missing .git/MERGE_HEAD
'

test_done
