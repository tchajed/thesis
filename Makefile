TEX_FILES := $(wildcard *.tex) \
	$(wildcard perennial/*.tex) \
	$(wildcard crash-logatom/*.tex) \
	$(wildcard go-txn/*.tex \
               go-txn/fig/*.tex go-txn/tables/*.tex) \
	$(wildcard daisy-nfs/*.tex \
               daisy-nfs/fig/*.tex) \
	$(wildcard goose/*.tex)
PLOTS := daisy-nfs/fig/bench.pdf \
	daisy-nfs/fig/extended-bench.pdf \
	daisy-nfs/fig/extended-bench-ram.pdf \
	daisy-nfs/fig/scale.pdf daisy-nfs/fig/scale-ram.pdf
DEPS := $(TEX_FILES) $(wildcard *.bib) $(wildcard fig/*.png) $(PLOTS)

default: thesis.pdf abstract.txt

thesis.pdf: $(DEPS)
	./latexrun --latex-args='-shell-escape' --bibtex-args=-min-crossrefs=100 -W no-overfull -W no-tabfigures thesis.tex

abstract.txt: frontmatter/abstract.tex
	cat $< | \
		pandoc -o $@ -f latex -t plain --wrap=none

#daisy-nfs/fig/bench.pdf: daisy-nfs/fig/bench.plot daisy-nfs/data/nvme/bench.data
#	@echo "daisy-nfs bench.plot"
#	@cd daisy-nfs; ./fig/bench.plot --input data/nvme/bench.data --output fig/bench.pdf

daisy-nfs/fig/bench.pdf: daisy-nfs/fig/bench.plot daisy-nfs/data/bench.data
	@echo "daisy-nfs bench.plot"
	@cd daisy-nfs; ./fig/bench.plot --input data/bench.data --output fig/bench.pdf

daisy-nfs/fig/extended-bench.pdf: daisy-nfs/fig/extended-bench.plot daisy-nfs/data/nvme/extended-bench.data
	@echo "daisy-nfs extended-bench.plot"
	@cd daisy-nfs; ./fig/extended-bench.plot --input data/nvme/extended-bench.data --output fig/extended-bench.pdf

daisy-nfs/fig/extended-bench-ram.pdf: daisy-nfs/fig/extended-bench.plot daisy-nfs/data/extended-bench.data
	@echo "daisy-nfs extended-bench.plot (RAM)"
	@cd daisy-nfs; ./fig/extended-bench.plot --input data/extended-bench.data --output fig/extended-bench-ram.pdf

daisy-nfs/fig/scale.pdf: daisy-nfs/fig/scale.plot daisy-nfs/data/nvme/daisy-nfsd.data daisy-nfs/data/nvme/linux.data
	@echo "daisy-nfs scale.plot (NVMe)"
	@cd daisy-nfs; ./fig/scale.plot --input data/nvme --output fig/scale.pdf --legend "right center"

daisy-nfs/fig/scale-ram.pdf: daisy-nfs/fig/scale.plot daisy-nfs/data/daisy-nfsd.data daisy-nfs/data/linux.data
	@echo "daisy-nfs scale.plot (RAM)"
	@cd daisy-nfs; ./fig/scale.plot --input data --output fig/scale-ram.pdf


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
