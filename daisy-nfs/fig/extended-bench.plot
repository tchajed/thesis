#!/bin/bash

set -eu

output=fig/extended-bench.pdf
input=data/extended-bench.data

usage() {
    echo "Usage: $0 [--input INPUT] [--output OUTPUT]" 1>&2
    echo "defaults to plotting from data/bench.data" 1>&2
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -i | --input)
        shift
        input="$1"
        if [ -d "$input" ]; then
            input="$input/extended-bench.data"
        fi
        shift
        ;;
    -o | --output)
        shift
        output="$1"
        shift
        ;;
    -h | -help | --help)
        usage
        exit 0
        ;;
    *)
        echo "unknown option $1" 1>&2
        usage
        exit 1
        ;;
    esac
done

line1='column("linux")/column("linux")'
line2='column("linux-ordered")/column("linux")'
line3='column("daisy-nfsd")/column("linux")'
line4='column("daisy-nfsd-seq-txn")/column("linux")'
line5='column("daisy-nfsd-seq-wal")/column("linux")'
# smallfile-1
label1=$(awk 'NR==2 {printf "%.0f", $2}' "$input")
# smallfile-par
label2=$(awk 'NR==3 {printf "%.0f", $2}' "$input")
# largefile
label3=$(awk 'NR==4 {printf "%.0f", $2}' "$input")
# app
label4=$(awk 'NR==5 {printf "%0.3f", $2}' "$input")

gnuplot <<-EOF
	set terminal pdf dashed noenhanced font "Charter,12" size 5in,2.3in
	set output "${output}"

	set style data histogram
	set style histogram cluster gap 1
	set rmargin at screen .95

	set xrange [-0.8:4.5]
	set yrange [0:2.2]
	set grid y
	set ylabel "Relative througput"
	set ytics scale 0.5,0 nomirror
	set xtics scale 0,0
	set key top right
	set style fill solid 1 border rgb "black"

	set label '${label1} file/s' at (0.08 -4./7),1.1 right rotate by 90 offset character 0,-1
	set label '${label2} file/s' at (1.08 -4./7),1.1 right rotate by 90 offset character 0,-1
	set label '${label3} MB/s' at (2.08 -4./7),1.1 right rotate by 90 offset character 0,-1
	set label '${label4} app/s' at (3.08 -4./7),1.1 right rotate by 90 offset character 0,-1

	set datafile separator "\t"

	plot "${input}" \
	        using (${line1}):xtic(1) title "Linux" lc rgb '#0071b2' lt 1, \
	     '' using (${line2}):xtic(1) title "Linux (log bypass)" lc rgb '#80b8d8' lt 1, \
	     '' using (${line3}):xtic(1) title "DaisyNFS" lc rgb '#009e73' lt 1, \
	     '' using (${line4}):xtic(1) title "DaisyNFS (seq txn)" lc rgb '#4cbb9d' lt 1, \
	     '' using (${line5}):xtic(1) title "DaisyNFS (seq wal)" lc rgb '#b2e2d5' lt 1

EOF
