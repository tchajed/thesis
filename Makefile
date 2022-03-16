MD_FILES:=$(wildcard *.md)

PDFS:=$(MD_FILES:.md=.pdf) thesis.pdf proposal.pdf

DEPS := $(wildcard *.tex) \
	$(wildcard goose/*.tex) \
	$(wildcard perennial/*.tex) \
	$(wildcard daisy-nfs/*.tex \
               daisy-nfs/fig/*.tex) \
	$(wildcard go-journal/*.tex \
               go-journal/fig/*.tex go-journal/tables/*.tex) \
	$(wildcard *.bib)

default: thesis.pdf abstract.txt

thesis.pdf: thesis.tex $(DEPS)
	./latexrun --latex-args='-shell-escape' --bibtex-args=-min-crossrefs=100 $<

abstract.txt: abstract.tex
	cat $< | \
		pandoc -o $@ -f latex -t plain --wrap=none

PROPOSAL_DEPS := proposal-abstract.tex \
	01-introduction.tex \
	proposal-timeline.tex \
	$(wildcard *.tex)

proposal.pdf: proposal.tex $(PROPOSAL_DEPS)
	./latexrun --latex-args='-shell-escape' $<

%.pdf: %.md
	pandoc $< -o $@

clean:
	latexrun --clean
	rm -f *.pdf
