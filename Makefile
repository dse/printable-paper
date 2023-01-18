DOTGRID_HALF_LETTER_SVG		= paper/dotgrid-half-letter.svg
LINEGRID4_HALF_LETTER_SVG	= paper/linegrid4-half-letter.svg
LINEGRID3_HALF_LETTER_SVG	= paper/linegrid3-half-letter.svg
DOTGRID_LETTER_SVG		= paper/dotgrid-letter.svg
LINEGRID4_LETTER_SVG		= paper/linegrid4-letter.svg
LINEGRID3_LETTER_SVG		= paper/linegrid3-letter.svg

DOTGRID		= bin/dotgrid
LINEGRID	= bin/linegrid
TWOUPTWOPAGE	= bin/2up2page
TWOUP      	= bin/2up

SVG_LETTER      = $(DOTGRID_LETTER_SVG)      $(LINEGRID4_LETTER_SVG)      $(LINEGRID3_LETTER_SVG)
SVG_HALF_LETTER = $(DOTGRID_HALF_LETTER_SVG) $(LINEGRID4_HALF_LETTER_SVG) $(LINEGRID3_HALF_LETTER_SVG)

PDF_LETTER      = $(patsubst %.svg,%.pdf,$(SVG_LETTER))
PDF_HALF_LETTER = $(patsubst %.svg,%.pdf,$(SVG_HALF_LETTER))

SVG             = $(SVG_LETTER) $(SVG_HALF_LETTER)
PDF             = $(PDF_LETTER) $(PDF_HALF_LETTER)

PDF2UP          = $(patsubst %.pdf,%.2up.pdf,$(PDF_HALF_LETTER))
PDF2UP2PAGE     = $(patsubst %.pdf,%.2up2page.pdf,$(PDF_HALF_LETTER))

ALLPDF          = $(PDF) $(PDF2UP) $(PDF2UP2PAGE)
ALLPS           = $(patsubst %.pdf,%.ps,$(ALLPDF))

INKSCAPE_OPTIONS =
PDF2PS_OPTIONS   = 

default: letter halfletter 2up 2up2page
letter: $(SVG_LETTER) $(PDF_LETTER)
halfletter: $(SVG_HALF_LETTER) $(PDF_HALF_LETTER)
2up: $(PDF2UP)
2up2page: $(PDF2UP2PAGE)

$(DOTGRID_HALF_LETTER_SVG):   $(LINEGRID) Makefile ; $(LINEGRID) --dot-grid --grid-style=5mm   --page-size=half-letter > "$@.tmp" && mv "$@.tmp" "$@"
$(LINEGRID4_HALF_LETTER_SVG): $(LINEGRID) Makefile ; $(LINEGRID)            --grid-style=2mm,4 --page-size=half-letter > "$@.tmp" && mv "$@.tmp" "$@"
$(LINEGRID3_HALF_LETTER_SVG): $(LINEGRID) Makefile ; $(LINEGRID)            --grid-style=2mm,3 --page-size=half-letter > "$@.tmp" && mv "$@.tmp" "$@"
$(DOTGRID_LETTER_SVG):        $(LINEGRID) Makefile ; $(LINEGRID) --dot-grid --grid-style=5mm   --page-size=letter      > "$@.tmp" && mv "$@.tmp" "$@"
$(LINEGRID4_LETTER_SVG):      $(LINEGRID) Makefile ; $(LINEGRID)            --grid-style=2mm,4 --page-size=letter      > "$@.tmp" && mv "$@.tmp" "$@"
$(LINEGRID3_LETTER_SVG):      $(LINEGRID) Makefile ; $(LINEGRID)            --grid-style=2mm,3 --page-size=letter      > "$@.tmp" && mv "$@.tmp" "$@"

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
