DOTGRID = bin/dotgrid
TWOUPTWOPAGE = bin/2up2page
SVG = dotgrid.svg
PDF = dotgrid.pdf
PDF2UP2PAGE = dotgrid.2up2page.pdf

default: $(SVG) $(PDF) $(PDF2UP2PAGE)

$(SVG): $(DOTGRID) Makefile
	$(DOTGRID) > $(SVG).tmp
	mv $(SVG).tmp $(SVG)

%.pdf: %.svg Makefile
	inkscape "$<" --export-dpi=600 -o "$@"

%.2up2page.pdf: %.pdf Makefile $(TWOUPTWOPAGE)
	$(TWOUPTWOPAGE) "$<"

clean:
	rm $(SVG) $(PDF) $(PDF2UP2PAGE)
