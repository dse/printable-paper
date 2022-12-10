PROGRAM = bin/dotgrid
SVG = dotgrid.svg
$(SVG): $(PROGRAM) Makefile
	$(PROGRAM) > $(SVG).tmp
	mv $(SVG).tmp $(SVG)
