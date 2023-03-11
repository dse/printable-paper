SVG = paper/paper.svg
PDF = paper/paper.pdf
LINEGRID = bin/linegrid
TWOUP = bin/2up
PDF2UP = $(patsubst %.pdf,%.2up.pdf,$(PDF))
INKSCAPE_OPTIONS =
PDF2PS_OPTIONS =

default: $(PDF)
$(SVG): $(LINEGRID) Makefile
	$(LINEGRID) --grid-style=1/16in,4,16 --page-size=letter --stroke-widths='1/600in,2/600in,3/600in'  > "$@.tmp"
	mv "$@.tmp" "$@"

%.pdf: %.svg Makefile
	inkscape $(INKSCAPE_OPTIONS) --export-dpi=600 --export-filename="$@.tmp.pdf" "$<"
	mv "$@.tmp.pdf" "$@"
%.ps: %.pdf Makefile
	pdf2ps $(PDF2PS_OPTIONS) "$<" "$@.tmp.ps"
	mv "$@.tmp.ps" "$@"
%.2up2page.pdf: %.pdf Makefile $(TWOUPTWOPAGE)
	$(TWOUPTWOPAGE) "$<"
%.2up.pdf: %.pdf Makefile $(TWOUP)
	$(TWOUP) "$<"

clean:
	rm $(ALLPS) $(ALLPDF) $(SVG) 2>/dev/null || true
