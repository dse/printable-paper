DOTGRID_SVG	= paper/dotgrid.svg
LINEGRID10_SVG	= paper/linegrid10.svg
LINEGRID12_SVG	= paper/linegrid12.svg
LINEGRID412_SVG = paper/linegrid412-letter.svg
LINEGRID4_SVG   = paper/linegrid4-letter.svg

DOTGRID		= bin/dotgrid
LINEGRID	= bin/linegrid
TWOUPTWOPAGE	= bin/2up2page

SVG_LETTER      = paper/linegrid412-letter.svg \
                  paper/linegrid4-letter.svg
PDF_LETTER      = $(patsubst %.svg,%.pdf,$(SVG_LETTER))

SVG             = paper/dotgrid.svg \
		  paper/linegrid10.svg \
		  paper/linegrid12.svg \
		  paper/linegrid412-letter.svg
PDF             = $(patsubst %.svg,%.pdf,$(SVG))
PDF2UP2PAGE     = $(patsubst %.svg,%.2up2page.pdf,$(SVG))

ALLPDF          = $(PDF) $(PDF2UP2PAGE)
ALLPS           = $(patsubst %.pdf,%.ps,$(ALLPDF))

INKSCAPE_OPTIONS =
PDF2PS_OPTIONS   = 

default: $(SVG) $(PDF) $(PDF2UP2PAGE) $(ALLPS)
pdf: $(SVG) $(PDF) $(PDF2UP2PAGE)
letter: $(SVG_LETTER) $(PDF_LETTER)

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
	$(LINEGRID) --style=2.5mm,10 >"$@.tmp"
	mv "$@.tmp" "$@"

$(LINEGRID12_SVG): $(LINEGRID) Makefile
	$(LINEGRID) --style=2mm,12 >"$@.tmp"
	mv "$@.tmp" "$@"

$(LINEGRID412_SVG): $(LINEGRID) Makefile
	$(LINEGRID) --letter --style=2mm,4,12 >"$@.tmp"
	mv "$@.tmp" "$@"

$(LINEGRID4_SVG): $(LINEGRID) Makefile
	$(LINEGRID) --letter --style=2mm,4 >"$@.tmp"
	mv "$@.tmp" "$@"

%.pdf: %.svg Makefile
	inkscape $(INKSCAPE_OPTIONS) --export-dpi=600 --export-filename="$@.tmp.pdf" "$<"
	mv "$@.tmp.pdf" "$@"

%.ps: %.pdf Makefile
	pdf2ps $(PDF2PS_OPTIONS) "$<" "$@.tmp.ps"
	mv "$@.tmp.ps" "$@"

%.2up2page.pdf: %.pdf Makefile $(TWOUPTWOPAGE)
	$(TWOUPTWOPAGE) "$<"

clean:
	rm $(ALLPS) $(ALLPDF) $(SVG) 2>/dev/null || true
