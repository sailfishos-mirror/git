# This function uses a trick to manipulate the interactive add to use color:
# the `want_color()` function special-cases the situation where a pager was
# spawned and Git now wants to output colored text: to detect that situation,
# the environment variable `GIT_PAGER_IN_USE` is set. However, color is
# suppressed despite that environment variable if the `TERM` variable
# indicates a dumb terminal, so we set that variable, too.

force_color () {
	env GIT_PAGER_IN_USE=true TERM=vt100 "$@"
}

	test_write_lines d 1 | git add -i >output &&
	test_write_lines r 1 | git add -i &&
test_expect_success 'add untracked (multiple)' '
	test_when_finished "git reset && rm [1-9]" &&
	touch $(test_seq 9) &&
	test_write_lines a "2-5 8-" | git add -i -- [1-9] &&
	test_write_lines 2 3 4 5 8 9 >expected &&
	git ls-files [1-9] >output &&
	test_cmp expected output
'

	test_write_lines d 1 | git add -i >output &&
	test_write_lines r 1 | git add -i &&
	test_write_lines e a | git add -p &&
	test_write_lines e n d | git add -p >output &&
	test_write_lines e n d | git add -p >output &&