MD_FILES:=$(wildcard *.md)

PDFS:=$(MD_FILES:.md=.pdf) thesis.pdf proposal.pdf

all: $(PDFS)

thesis.pdf: thesis.tex $(wildcard *.tex) $(wildcard *.bib)
	latexrun --latex-args='-shell-escape' $<

proposal.pdf: proposal.tex $(wildcard *.tex) $(wildcard *.bib)
	latexrun --latex-args='-shell-escape' $<

%.pdf: %.md
	pandoc $< -o $@

clean:
	latexrun --clean
	rm -f *.pdf
