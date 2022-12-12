DOTGRID_SVG = dotgrid.svg
LINEGRID10_SVG = linegrid10.svg
LINEGRID12_SVG = linegrid12.svg
LINEGRID412_SVG = linegrid412.svg

DOTGRID = bin/dotgrid
LINEGRID = bin/linegrid
TWOUPTWOPAGE = bin/2up2page

SVG =   dotgrid.svg \
	linegrid10.svg \
	linegrid12.svg \
	linegrid412.svg
PDF         = $(patsubst %.svg,%.pdf,$(SVG))
PDF2UP2PAGE = $(patsubst %.svg,%.2up2page.pdf,$(SVG))

ALLPDF      = $(PDF) $(PDF2UP2PAGE)
ALLPS       = $(patsubst %.pdf,%.ps,$(ALLPDF))

default: $(SVG) $(PDF) $(PDF2UP2PAGE) $(ALLPS)

echo:
	@echo SVG $(SVG)
	@echo PDF $(PDF)
	@echo PDF2UP2PAGE $(PDF2UP2PAGE)
	@echo ALLPDF $(ALLPDF)
	@echo ALLPS $(ALLPS)

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
	inkscape "$<" --export-dpi=600 -o "$@.tmp.pdf"
	mv "$@.tmp.pdf" "$@"

%.ps: %.pdf Makefile
	pdf2ps "$<" "$@.tmp.ps"
	mv "$@.tmp.ps" "$@"

%.2up2page.pdf: %.pdf Makefile $(TWOUPTWOPAGE)
	$(TWOUPTWOPAGE) "$<"

clean:
	rm $(ALLPS) $(ALLPDF) $(SVG) 2>/dev/null || true
