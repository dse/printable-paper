PNGS = \
    downloads/darrens-grid-a4.png \
    downloads/darrens-grid-a5.png \
    downloads/darrens-grid-letter.png \
    downloads/darrens-grid-half-letter.png

.PHONY: default clean rsync png

default:
	mkdir -p downloads
	cd downloads && ../bin/darrensgrid
	cd downloads && ../bin/frenchruled
	make png rsync

png: $(PNGS)

rsync:
	rsync -av downloads/ dse@webonastick.com:/www/webonastick.com/htdocs/paper/downloads/

%.png: %.svg Makefile
	convert -density 200 $< $@

clean:
	find . -type f \( -name '*.pdf' -o -name '*.svg' -o -name '*.png' \) -exec rm {} +
