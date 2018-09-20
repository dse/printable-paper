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

ps:  templates/line-dot-grid-letter.ps  templates/dot-grid-letter.ps

pdf: templates/line-dot-grid-letter.pdf       templates/dot-grid-letter.pdf \
     templates/line-dot-grid-letter.2page.pdf templates/dot-grid-letter.2page.pdf \

svg: templates/line-dot-grid-letter.svg templates/dot-grid-letter.svg

templates/line-dot-grid-letter.svg: bin/printable Makefile
	mkdir -p templates
	bin/printable line-dot-grid  >templates/line-dot-grid-letter.svg

templates/dot-grid-letter.svg: bin/printable
	mkdir -p templates
	bin/printable dot-grid >templates/dot-grid-letter.svg

templates/line-dot-grid-letter-2page.pdf: templates/line-dot-grid-letter.pdf
	if which pdfunite >/dev/null 2>/dev/null ; then \
		pdfunite templates/line-dot-grid-letter.pdf templates/line-dot-grid-letter.pdf "$@.tmp.pdf" ; \
	else \
		false ; \
	fi
	mv "$@.tmp.pdf" "$@"

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
