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

default:
	makebin/makeprintable

# file formats
ps:
	makebin/makeprintable ps
pdf:
	makebin/makeprintable pdf
svg:
	makebin/makeprintable svg

# specialties
2-up:
	makebin/makeprintable 2-up

# paper sizes
a4:
	makebin/makeprintable a4
a5:
	makebin/makeprintable a5
letter:
	makebin/makeprintable letter
halfletter:
	makebin/makeprintable half-letter

# rulings
dot-grid:
	makebin/makeprintable dot-grid
line-dot-grid:
	makebin/makeprintable line-dot-grid
line-dot-graph:
	makebin/makeprintable line-dot-graph
seyes:
	makebin/makeprintable seyes
quadrille:
	makebin/makeprintable quadrille

# actions
clean:
	makebin/makeprintable CLEAN
clean-svg:
	makebin/makeprintable CLEAN svg
list:
	makebin/makeprintable LIST
list-svg:
	makebin/makeprintable LIST svg

%.pdf: makebin/makeprintable bin/printable Makefile
	makebin/makeprintable "$@"
%.svg: makebin/makeprintable bin/printable Makefile
	makebin/makeprintable "$@"
%.ps: makebin/makeprintable bin/printable Makefile
	makebin/makeprintable "$@"

.PHONY: ps pdf svg 2-up a4 a5 letter halfletter dot-grid line-dot-grid line-dot-graph seyes clean list clean-svg list-svg
