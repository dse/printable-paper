SHELL = bash
INKSCAPE = inkscape

# darwin: inkscape invokes an app installed in /Applications which
# changes the working directory before being invoked.
PATHNAME = $(shell \
	if [[ "$$OSTYPE" = "darwin"* ]] ; then \
		echo realpath ; \
	else \
		echo echo ; \
	fi \
)

default: svg pdf

RULINGS = \
	seyes--letter \
	seyes-with-thinner-grid-lines--letter \
	line-dot-graph--letter \
	dot-grid--letter \
	seyes--a4 \
	seyes-with-thinner-grid-lines--a4 \
	line-dot-graph--a4 \
	dot-grid--a4 \

PS_FILES	= $(patsubst %,templates/%.ps,$(RULINGS))
PDF_FILES	= $(patsubst %,templates/%.pdf,$(RULINGS))
PDF_2PAGE_FILES = $(patsubst %,templates/%.2page.pdf,$(RULINGS))
SVG_FILES	= $(patsubst %,templates/%.svg,$(RULINGS))

ps:  $(PS_FILES)
pdf: $(PDF_FILES) $(PDF_2PAGE_FILES)
svg: $(SVG_FILES)

clean:
	rm $(PS_FILES) $(PDF_FILES) $(PDF_2PAGE_FILES) $(SVG_FILES) || true
	find . -type f \( -name '*.tmp' -o -name '*.tmp.*' \) -exec rm {} + || true

# more specific rules first, for non-gnu make
# thinner, lighter, fainter
templates/%-with-thinner-grid-lines--letter.svg: bin/printable Makefile
	mkdir -p templates
	bin/printable -M letter --modifier=thinner-grid-lines $* >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"
templates/%-with-thinner-grid-lines--a4.svg: bin/printable Makefile
	mkdir -p templates
	bin/printable -M a4 --modifier=thinner-grid-lines $* >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"

# generic rules later, for non-gnu make
templates/%--letter.svg: bin/printable Makefile
	mkdir -p templates
	bin/printable -M letter $* >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"
templates/%--a4.svg: bin/printable Makefile
	mkdir -p templates
	bin/printable -M a4 $* >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"

%.2page.pdf: %.pdf
	if which pdfunite >/dev/null 2>/dev/null ; then \
		pdfunite "$<" "$<" "$@.tmp.pdf" ; \
	else \
		false ; \
	fi
	mv "$@.tmp.pdf" "$@"

%.pdf: %.svg Makefile
	$(INKSCAPE) --without-gui --export-dpi=300 --export-pdf \
		"$$($(PATHNAME) "$@.tmp.pdf")" \
		"$$($(PATHNAME) "$<")"
	mv "$@.tmp.pdf" "$@"

%.ps: %.svg Makefile
	$(INKSCAPE) --without-gui --export-dpi=300 --export-ps "$@.tmp.ps" "$<"
	mv "$@.tmp.ps" "$@"
