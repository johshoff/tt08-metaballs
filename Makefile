playground:
	cat src-playground/* src/metaballs.v | sed -e '/verilator lint_off WIDTHTRUNC/d' | pbcopy
	@echo "\nPaste into https://tinytapeout.github.io/vga-playground/"
