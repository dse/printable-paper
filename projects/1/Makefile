.PHONY: default clean rsync png
default:
	mkdir -p downloads
	cd downloads && ../bin/grid2
	make png rsync
png: downloads/paper-a4.png downloads/paper-a5.png downloads/paper-letter.png downloads/paper-half-letter.png
rsync:
	rsync -av downloads/ dse@webonastick.com:/www/webonastick.com/htdocs/paper/downloads/
%.png: %.svg Makefile
	convert -density 200 $< $@
clean:
	find . -type f \( -name '*.pdf' -o -name '*.svg' -o -name '*.png' \) -exec rm {} +
