# DOTGRID_HALF_LETTER_SVG		= paper/dotgrid-half-letter.svg
# LINEGRID4_HALF_LETTER_SVG	= paper/linegrid4-half-letter.svg
# LINEGRID3_HALF_LETTER_SVG	= paper/linegrid3-half-letter.svg
# DOTGRID_LETTER_SVG		= paper/dotgrid-letter.svg
# LINEGRID4_LETTER_SVG		= paper/linegrid4-letter.svg
# LINEGRID3_LETTER_SVG		= paper/linegrid3-letter.svg
LINEGRID_A5_SVG                 = paper/linegrid-a5.svg

DOTGRID		= bin/dotgrid
LINEGRID	= bin/linegrid
TWOUPTWOPAGE	= bin/2up2page
TWOUP      	= bin/2up

# SVG_LETTER      = $(DOTGRID_LETTER_SVG)      $(LINEGRID4_LETTER_SVG)      $(LINEGRID3_LETTER_SVG)
# SVG_HALF_LETTER = $(DOTGRID_HALF_LETTER_SVG) $(LINEGRID4_HALF_LETTER_SVG) $(LINEGRID3_HALF_LETTER_SVG)
SVG_A5          = $(LINEGRID_A5_SVG)

# PDF_LETTER      = $(patsubst %.svg,%.pdf,$(SVG_LETTER))
# PDF_HALF_LETTER = $(patsubst %.svg,%.pdf,$(SVG_HALF_LETTER))
PDF_A5          = $(patsubst %.svg,%.pdf,$(SVG_A5))

# SVG             = $(SVG_LETTER) $(SVG_HALF_LETTER)
# PDF             = $(PDF_LETTER) $(PDF_HALF_LETTER)
SVG             = $(SVG_A5)
PDF             = $(PDF_A5)

PDF2UP_A5       = $(patsubst %.pdf,%.2up.pdf,$(PDF_A5))
PDF2UP2PAGE_A5  = $(patsubst %.pdf,%.2up2page.pdf,$(PDF_A5))

ALLPDF          = $(PDF) $(PDF2UP) $(PDF2UP2PAGE)
ALLPS           = $(patsubst %.pdf,%.ps,$(ALLPDF))

INKSCAPE_OPTIONS =
PDF2PS_OPTIONS   = 

default: a5 2up 2up2page
svg: $(SVG)
pdf: $(PDF)
a5: $(SVG_A5)
2up: $(PDF2UP_A5)
2up2page: $(PDF2UP2PAGE_A5)

# $(DOTGRID_HALF_LETTER_SVG):   $(LINEGRID) Makefile ; $(LINEGRID) --dot-grid --grid-style=5mm   --page-size=half-letter > "$@.tmp" && mv "$@.tmp" "$@"
# $(LINEGRID4_HALF_LETTER_SVG): $(LINEGRID) Makefile ; $(LINEGRID)            --grid-style=2mm,4 --page-size=half-letter > "$@.tmp" && mv "$@.tmp" "$@"
# $(LINEGRID3_HALF_LETTER_SVG): $(LINEGRID) Makefile ; $(LINEGRID)            --grid-style=2mm,3 --page-size=half-letter > "$@.tmp" && mv "$@.tmp" "$@"
# $(DOTGRID_LETTER_SVG):        $(LINEGRID) Makefile ; $(LINEGRID) --dot-grid --grid-style=5mm   --page-size=letter      > "$@.tmp" && mv "$@.tmp" "$@"
# $(LINEGRID4_LETTER_SVG):      $(LINEGRID) Makefile ; $(LINEGRID)            --grid-style=2mm,4 --page-size=letter      > "$@.tmp" && mv "$@.tmp" "$@"
# $(LINEGRID3_LETTER_SVG):      $(LINEGRID) Makefile ; $(LINEGRID)            --grid-style=2mm,3 --page-size=letter      > "$@.tmp" && mv "$@.tmp" "$@"
$(LINEGRID_A5_SVG): $(LINEGRID) Makefile
	$(LINEGRID) --grid-style=2mm,3,12 --page-size=a5 --stroke-widths='1/600in,2/600in,3/600in'  > "$@.tmp"
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
