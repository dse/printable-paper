DOTGRID_SVG	= paper/dotgrid.svg
LINEGRID10_SVG	= paper/linegrid10.svg
LINEGRID12_SVG	= paper/linegrid12.svg
LINEGRID412_SVG = paper/linegrid412.svg
LINEGRID416_SVG = paper/linegrid416.svg

DOTGRID		= bin/dotgrid
LINEGRID	= bin/linegrid
TWOUPTWOPAGE	= bin/2up2page

SVG             = paper/dotgrid.svg \
		  paper/linegrid10.svg \
		  paper/linegrid12.svg \
		  paper/linegrid412.svg \
		  paper/linegrid416.svg
PDF             = $(patsubst %.svg,%.pdf,$(SVG))
PDF2UP2PAGE     = $(patsubst %.svg,%.2up2page.pdf,$(SVG))

ALLPDF          = $(PDF) $(PDF2UP2PAGE)
ALLPS           = $(patsubst %.pdf,%.ps,$(ALLPDF))

default: $(SVG) $(PDF) $(PDF2UP2PAGE) $(ALLPS)

echo:
	@echo SVG $(SVG)
	@echo PDF $(PDF)
	@echo PDF2UP2PAGE $(PDF2UP2PAGE)
	@echo ALLPDF $(ALLPDF)
	@echo ALLPS $(ALLPS)

env:
	env

# LINEGRID_COLOR = --color='\#000000' --dash-array=2/600in,6/600in
LINEGRID_COLOR =

LINEGRID10  = $(LINEGRID) $(LINEGRID_COLOR) --spacing=1/10in,1/2in,1in   --stroke-width=2/600in,4/600in,8/600in --dy=0.125in
LINEGRID12  = $(LINEGRID) $(LINEGRID_COLOR) --spacing=1/12in,1/2in,1in   --stroke-width=2/600in,4/600in,8/600in --dy=0.125in
LINEGRID412 = $(LINEGRID) $(LINEGRID_COLOR) --spacing=1/12in,1/4in,1in   --stroke-width=2/600in,4/600in,8/600in --dy=0.125in
LINEGRID416 = $(LINEGRID) $(LINEGRID_COLOR) --spacing=1/12in,1/3in,4/3in --stroke-width=2/600in,4/600in,8/600in --dy=0.125in

$(DOTGRID_SVG): $(DOTGRID) Makefile
	$(DOTGRID) >"$@.tmp"
	mv "$@.tmp" "$@"

$(LINEGRID10_SVG): $(LINEGRID) Makefile
	$(LINEGRID10) >"$@.tmp"
	mv "$@.tmp" "$@"

$(LINEGRID12_SVG): $(LINEGRID) Makefile
	$(LINEGRID12) >"$@.tmp"
	mv "$@.tmp" "$@"

$(LINEGRID412_SVG): $(LINEGRID) Makefile
	$(LINEGRID412) >"$@.tmp"
	mv "$@.tmp" "$@"

$(LINEGRID416_SVG): $(LINEGRID) Makefile
	$(LINEGRID416) >"$@.tmp"
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
