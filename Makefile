MD_FILES:=$(wildcard *.md)

PDFS:=$(MD_FILES:.md=.pdf)

all: $(PDFS)

%.pdf: %.md
	pandoc $< -o $@
