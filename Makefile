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
ps:
	makebin/makeprintable ps
pdf:
	makebin/makeprintable pdf
svg:
	makebin/makeprintable svg
clean:
	makebin/makeprintable CLEAN
list:
	makebin/makeprintable LIST
%.pdf:
	makebin/makeprintable "$@"
%.svg:
	makebin/makeprintable "$@"
%.ps:
	makebin/makeprintable "$@"
.PHONY: %.pdf %.svg %.ps
