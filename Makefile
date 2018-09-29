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

RULINGS = line-dot-grid-letter dot-grid-letter seyes-letter

PS_FILES	= $(patsubst %,templates/%.ps,$(RULINGS))
PDF_FILES	= $(patsubst %,templates/%.pdf,$(RULINGS))
PDF_2PAGE_FILES = $(patsubst %,templates/%.2page.pdf,$(RULINGS))
SVG_FILES	= $(patsubst %,templates/%.svg,$(RULINGS))

ps:  $(PS_FILES)
pdf: $(PDF_FILES) $(PDF_2PAGE_FILES)
svg: $(SVG_FILES)

clean:
	rm $(PS_FILES) $(PDF_FILES) $(PDF_2PAGE_FILES) $(SVG_FILES) || true

templates/line-dot-grid-letter.svg: bin/printable Makefile
	mkdir -p templates
	bin/printable five-sixteenths-inch-line-dot-grid >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"

templates/dot-grid-letter.svg: bin/printable
	mkdir -p templates
	bin/printable one-quarter-inch-dot-grid >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"

templates/seyes-letter.svg: bin/printable
	mkdir -p templates
	bin/printable seyes-ruling >"$@.tmp.svg"
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
