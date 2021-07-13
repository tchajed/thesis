MD_FILES:=$(wildcard *.md)

PDFS:=$(MD_FILES:.md=.pdf) thesis.pdf

all: $(PDFS)

thesis.pdf: $(wildcard *.tex) $(wildcard *.bib)
	latexrun --latex-args='-shell-escape' thesis.tex

%.pdf: %.md
	pandoc $< -o $@

clean:
	latexrun --clean
	rm -f *.pdf
