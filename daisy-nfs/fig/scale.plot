#!/bin/bash

set -eu

output=fig/scale.pdf
input=data/
legend="top left"
ymax="*"

usage() {
    echo "Usage: $0 [--input INPUT] [--output OUTPUT]" 1>&2
    echo "defaults to plotting from data/" 1>&2
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -i | --input)
        shift
        input="$1"
        shift
        ;;
    -o | --output)
        shift
        output="$1"
        shift
        ;;
    -l | --legend)
        shift
        legend="$1"
        shift
        ;;
    -y)
        shift
        ymax="$1"
        shift
        ;;
    -h | -help | --help)
        usage
        exit 0
        ;;
    *)
        echo "unknown argument $1" 1>&2
        usage
        exit 1
        ;;
    esac
done

daisy_last="$(tail -1 $input/daisy-nfsd.data | cut -f2)"
linux_last="$(tail -1 $input/linux.data | cut -f2)"
daisy_higher="$(echo | awk "{ print ($daisy_last > $linux_last) ? 1 : 0 }")"

daisy_line="\"${input}/daisy-nfsd.data\" using 1:(\$2) with linespoints ls 1 title 'DaisyNFS'"
linux_line="\"${input}/linux.data\" using 1:(\$2) with linespoints ls 2 title 'Linux NFS'"

if [[ "$daisy_higher" = "1" ]]; then
    plot_cmd="${daisy_line}, ${linux_line}"
else
    plot_cmd="${linux_line}, ${daisy_line}"
fi

if [ -f "${input}/daisy-nfsd-seq-txn.data" ]; then
    plot_cmd+=", \"${input}/daisy-nfsd-seq-txn.data\" using 1:(\$2) with linespoints ls 4 title 'DaisyNFS (seq txn)'"
fi
if [ -f "${input}/daisy-nfsd-seq-wal.data" ]; then
    plot_cmd+=", \"${input}/daisy-nfsd-seq-wal.data\" using 1:(\$2) with linespoints ls 3 title 'DaisyNFS (seq WAL)'"
fi

gnuplot <<-EOF
    set terminal pdf dashed noenhanced font "Charter,14" size 3.6in,2.6in
    set output "${output}"

    set auto x
    set yrange [0:${ymax}]
    set xtics 4
    set ylabel "files / sec"
    set format y '%.0s%c'
    set xlabel "\# clients"
    set key ${legend}

    set style data line

    set style line 81 lt 0  # dashed
    set style line 81 lt rgb "#808080"  # grey
    set grid back linestyle 81

    set border 3 back linestyle 80
    set style line 1 lt rgb "#009e73" lw 2 pt 6
    set style line 2 lt rgb "#0071b2" lw 2 pt 1
    # lighter versions of style 1
    set style line 3 lt rgb "#4cbb9d" lw 2 pt -1
    set style line 4 lt rgb "#b2e2d5" lw 2 pt -1

    plot ${plot_cmd}

    #"${input}/go-nfsd.data" using 1:(\$2) with linespoints ls 2 title 'GoNFS',
EOF
