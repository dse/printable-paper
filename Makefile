INKSCAPE = inkscape

default: svg pdf

ps:  templates/line-dot-grid-letter.ps  templates/dot-grid-letter.ps

pdf: templates/line-dot-grid-letter.pdf templates/dot-grid-letter.pdf

svg: templates/line-dot-grid-letter.svg templates/dot-grid-letter.svg

templates/line-dot-grid-letter.svg: bin/printable
	mkdir -p templates
	bin/printable line-dot-grid  >templates/line-dot-grid-letter.svg

templates/dot-grid-letter.svg: bin/printable
	mkdir -p templates
	bin/printable dot-grid >templates/dot-grid-letter.svg

# templates/line-dot-grid-letter-2page.pdf: templates/line-dot-grid-letter.pdf
# poppler
#	pdfunite templates/line-dot-grid-letter.pdf templates/line-dot-grid-letter.pdf >"$@.tmp.pdf"
#	mv "$@.tmp.pdf" "$@"

%.pdf: %.svg
	$(INKSCAPE) --without-gui --export-dpi=300 --export-pdf "$@.tmp.pdf" "$<"
	mv "$@.tmp.pdf" "$@"

%.ps: %.svg
	$(INKSCAPE) --without-gui --export-dpi=300 --export-ps "$@.tmp.ps" "$<"
	mv "$@.tmp.ps" "$@"
