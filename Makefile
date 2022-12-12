DOTGRID_SVG = dotgrid.svg
LINEGRID10_SVG = linegrid10.svg
LINEGRID12_SVG = linegrid12.svg
LINEGRID412_SVG = linegrid412.svg
SVG = dotgrid.svg linegrid10.svg linegrid12.svg linegrid412.svg
PDF = dotgrid.pdf linegrid10.pdf linegrid12.pdf linegrid412.pdf
PDF2UP2PAGE = dotgrid.2up2page.pdf linegrid10.2up2page.pdf linegrid12.2up2page.pdf linegrid412.2up2page.pdf

DOTGRID = bin/dotgrid
LINEGRID = bin/linegrid
TWOUPTWOPAGE = bin/2up2page

default: $(SVG) $(PDF) $(PDF2UP2PAGE)

$(DOTGRID_SVG): $(DOTGRID) Makefile
	$(DOTGRID) >"$@.tmp"
	mv "$@.tmp" "$@"

$(LINEGRID10_SVG): $(LINEGRID) Makefile
	$(LINEGRID) 10 >"$@.tmp"
	mv "$@.tmp" "$@"

$(LINEGRID12_SVG): $(LINEGRID) Makefile
	$(LINEGRID) 12 >"$@.tmp"
	mv "$@.tmp" "$@"

$(LINEGRID412_SVG): $(LINEGRID) Makefile
	$(LINEGRID) 412 >"$@.tmp"
	mv "$@.tmp" "$@"

%.pdf: %.svg Makefile
	inkscape "$<" --export-dpi=600 -o "$@"

%.2up2page.pdf: %.pdf Makefile $(TWOUPTWOPAGE)
	$(TWOUPTWOPAGE) "$<"

clean:
	rm $(SVG) $(PDF) $(PDF2UP2PAGE) || true
