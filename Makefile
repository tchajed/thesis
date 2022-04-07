MD_FILES:=$(wildcard *.md)

PDFS:=$(MD_FILES:.md=.pdf) thesis.pdf proposal.pdf

TEX_FILES := $(wildcard *.tex) \
	$(wildcard goose/*.tex) \
	$(wildcard perennial/*.tex) \
	$(wildcard daisy-nfs/*.tex \
               daisy-nfs/fig/*.tex) \
	$(wildcard go-txn/*.tex \
               go-txn/fig/*.tex go-txn/tables/*.tex)
DEPS := $(TEX_FILES) $(wildcard *.bib)

default: thesis.pdf abstract.txt

thesis.pdf: $(DEPS)
	./latexrun --latex-args='-shell-escape' --bibtex-args=-min-crossrefs=100 -W no-overfull thesis.tex

abstract.txt: abstract.tex
	cat $< | \
		pandoc -o $@ -f latex -t plain --wrap=none

spell:
	@ for i in *.tex */*.tex; do \
	aspell -l en_us --mode=tex \
					  --add-tex-command="citep p" \
					  --add-tex-command="citet p" \
					  --add-tex-command="Cref p" \
					  --add-tex-command="cref p" \
					  --add-tex-command="crefformat pp" \
					  --add-tex-command="tikzstyle p" \
					  --add-tex-command="usetikzlibrary p" \
					  --add-tex-command="definecolor ppp" \
					  --add-tex-command="newcommand pp" \
					  --add-tex-command="PY pp" \
					  --add-tex-command="cc p" \
					  --add-tex-command="figure p" \
					  --add-tex-command="renewcommand pp" \
					  -p ./aspell.words -c $$i; \
	done

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
