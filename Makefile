PROGRAM = bin/dotgrid
SVG = dotgrid.svg

default: dotgrid.pdf

$(SVG): $(PROGRAM) Makefile
	$(PROGRAM) > $(SVG).tmp
	mv $(SVG).tmp $(SVG)

%.pdf: %.svg Makefile
	inkscape "$<" --export-dpi=600 -o "$@"
