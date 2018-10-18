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

default: svg pdf ps

RULINGS = \
	seyes--letter \
	seyes--thinner-grid--letter \
	seyes--thinner-grid--halfletter \
	line-dot-graph--letter \
	line-dot-grid--letter \
	line-dot-grid--thinner--letter \
	line-dot-grid--x-thinner--letter \
	dot-grid--letter \
	seyes--a4 \
	seyes--thinner-grid--a4 \
	line-dot-graph--a4 \
	line-dot-grid--a4 \
	line-dot-grid--thinner--a4 \
	line-dot-grid--x-thinner--a4 \
	dot-grid--a4 \

PS_FILES	= $(patsubst %,templates/ps/%.ps,$(RULINGS))
PS_2PAGE_FILES	= $(patsubst %,templates/2-page-ps/%.2page.ps,$(RULINGS))
PDF_FILES	= $(patsubst %,templates/pdf/%.pdf,$(RULINGS))
PDF_2PAGE_FILES = $(patsubst %,templates/2-page-pdf/%.2page.pdf,$(RULINGS))
SVG_FILES	= $(patsubst %,templates/svg/%.svg,$(RULINGS))

TARGETS = $(PS_FILES) $(PS_2PAGE_FILES) $(PDF_FILES) $(PDF_2PAGE_FILES) $(SVG_FILES)

ps:  $(PS_FILES)  ${PS_2PAGE_FILES}
pdf: $(PDF_FILES) $(PDF_2PAGE_FILES)
svg: $(SVG_FILES)

clean:
	rm $(TARGETS) || true
	find . -type f \( -name '*.tmp' -o -name '*.tmp.*' \) -exec rm {} + || true

# more specific rules first, for non-gnu make
# thinner, lighter, fainter
templates/svg/%--thinner-grid--halfletter.svg: bin/printable Makefile
	mkdir -p "$$(dirname "$@")"
	bin/printable -M halfletter --modifier=thinner-grid --modifier=smaller $* >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"
templates/svg/%--thinner-grid--letter.svg: bin/printable Makefile
	mkdir -p "$$(dirname "$@")"
	bin/printable -M letter --modifier=thinner-grid $* >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"
templates/svg/%--thinner-grid--a4.svg: bin/printable Makefile
	mkdir -p "$$(dirname "$@")"
	bin/printable -M a4 --modifier=thinner-grid $* >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"

templates/svg/%--thinner--letter.svg: bin/printable Makefile
	mkdir -p "$$(dirname "$@")"
	bin/printable -M letter --modifier=thinner-dots --modifier=thinner-lines $* >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"
templates/svg/%--thinner--a4.svg: bin/printable Makefile
	mkdir -p "$$(dirname "$@")"
	bin/printable -M a4 --modifier=thinner-dots --modifier=thinner-lines $* >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"

templates/svg/%--x-thinner--letter.svg: bin/printable Makefile
	mkdir -p "$$(dirname "$@")"
	bin/printable -M letter --modifier=x-thinner-dots --modifier=x-thinner-lines $* >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"
templates/svg/%--x-thinner--a4.svg: bin/printable Makefile
	mkdir -p "$$(dirname "$@")"
	bin/printable -M a4 --modifier=x-thinner-dots --modifier=x-thinner-lines $* >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"

# generic rules later, for non-gnu make
templates/svg/%--letter.svg: bin/printable Makefile
	mkdir -p "$$(dirname "$@")"
	bin/printable -M letter $* >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"
templates/svg/%--a4.svg: bin/printable Makefile
	mkdir -p "$$(dirname "$@")"
	bin/printable -M a4 $* >"$@.tmp.svg"
	mv "$@.tmp.svg" "$@"

templates/2-page-pdf/%.2page.pdf: templates/pdf/%.pdf
	mkdir -p "$$(dirname "$@")"
	if which pdfunite >/dev/null 2>/dev/null ; then \
		pdfunite "$<" "$<" "$@.tmp.pdf" ; \
	else \
		false ; \
	fi
	mv "$@.tmp.pdf" "$@"

templates/2-page-ps/%.2page.ps: templates/ps/%.ps
	mkdir -p "$$(dirname "$@")"
	if which psselect >/dev/null 2>/dev/null ; then \
		psselect 1,1 "$<" >"$@.tmp.ps" ; \
	else \
		false ; \
	fi
	mv "$@.tmp.ps" "$@"

templates/pdf/%.pdf: templates/svg/%.svg Makefile
	mkdir -p "$$(dirname "$@")"
	$(INKSCAPE) --without-gui --export-dpi=300 --export-pdf \
		"$$($(PATHNAME) "$@.tmp.pdf")" \
		"$$($(PATHNAME) "$<")"
	mv "$@.tmp.pdf" "$@"

templates/ps/%.ps: templates/svg/%.svg Makefile
	mkdir -p "$$(dirname "$@")"
	$(INKSCAPE) --without-gui --export-dpi=300 --export-ps \
		"$$($(PATHNAME) "$@.tmp.ps")" \
		"$$($(PATHNAME) "$<")"
	mv "$@.tmp.ps" "$@"
