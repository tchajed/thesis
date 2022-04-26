TEX_FILES := $(wildcard *.tex) \
	$(wildcard perennial/*.tex) \
	$(wildcard crash-logatom/*.tex) \
	$(wildcard go-txn/*.tex \
               go-txn/fig/*.tex go-txn/tables/*.tex) \
	$(wildcard daisy-nfs/*.tex \
               daisy-nfs/fig/*.tex) \
	$(wildcard goose/*.tex)
DEPS := $(TEX_FILES) $(wildcard *.bib) $(wildcard fig/*.png) daisy-nfs/fig/bench.pdf daisy-nfs/fig/scale.pdf

default: thesis.pdf abstract.txt

thesis.pdf: $(DEPS)
	./latexrun --latex-args='-shell-escape' --bibtex-args=-min-crossrefs=100 -W no-overfull -W no-tabfigures thesis.tex

abstract.txt: frontmatter/abstract.tex
	cat $< | \
		pandoc -o $@ -f latex -t plain --wrap=none

daisy-nfs/fig/bench.pdf: daisy-nfs/fig/bench.plot daisy-nfs/data/bench.data
	@echo "gnuplot daisy-nfs/fig/bench.plot"
	@cd daisy-nfs; ./fig/bench.plot

daisy-nfs/fig/scale.pdf: daisy-nfs/fig/scale.plot daisy-nfs/data/daisy-nfsd.data daisy-nfs/data/linux.data
	@echo "gnuplot daisy-nfs/fig/scale.plot"
	@cd daisy-nfs; gnuplot ./fig/scale.plot


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

%.pdf: %.md
	pandoc $< -o $@

clean:
	latexrun --clean
	rm -f *.pdf
