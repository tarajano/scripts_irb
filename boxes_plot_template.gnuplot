## Template file of Gnuplot script
##
## Script created for plotting the distrib. of HPKDs with 3D strs/tmpls among the 
## nine HPK groups.
##
## This template is used the Perl script "strs_tmpls_per_hpkd_plusgnuplot_v2.pl"
## 

set terminal postscript eps enhanced color solid "Courier" 6

set tics out    
set xtics autofreq nomirror    
set ytics
set nox2tics    
set noy2tics

set style line 1 lt rgb "red" lw 1
set style line 2 lt rgb "blue" lw 1  
set style line 3 lt rgb "green" lw 1
set style line 4 lt rgb "gold" lw 1
set style line 5 lt rgb "brown" lw 1
set style line 6 lt rgb "dark-yellow" lw 1
set style line 7 lt rgb "orange" lw 1  
set style line 8 lt rgb "dark-green" lw 1  
set style line 9 lt rgb "dark-magenta" lw 1  

set xtics (XTICS_LABELS)
set xtics rotate by 90

set xlabel "HPK domains" 
set ylabel "Number of 3D structures/templates\n(log)"

set xrange [0:133]
set yrange [0.9:200]

set logscale y

set output "GNUPLOT_OUTPUT_FILE.eps"

plot\
"GNUPLOT_DATA_FILE" using 3:4 index 0 with boxes fs solid 0.3 ls 1 title "AGC",\
"GNUPLOT_DATA_FILE" using 3:5 index 0 with boxes fs solid 0.7 ls 1 notitle,\
"GNUPLOT_DATA_FILE" using 3:4 index 1 with boxes fs solid 0.3 ls 2 title "CAMK",\
"GNUPLOT_DATA_FILE" using 3:5 index 1 with boxes fs solid 0.7 ls 2 notitle,\
"GNUPLOT_DATA_FILE" using 3:4 index 2 with boxes fs solid 0.3 ls 3 title "CK1",\
"GNUPLOT_DATA_FILE" using 3:5 index 2 with boxes fs solid 0.7 ls 3 notitle,\
"GNUPLOT_DATA_FILE" using 3:4 index 3 with boxes fs solid 0.3 ls 4 title "CMGC",\
"GNUPLOT_DATA_FILE" using 3:5 index 3 with boxes fs solid 0.7 ls 4 notitle,\
"GNUPLOT_DATA_FILE" using 3:4 index 4 with boxes fs solid 0.3 ls 5 title "Other",\
"GNUPLOT_DATA_FILE" using 3:5 index 4 with boxes fs solid 0.7 ls 5 notitle,\
"GNUPLOT_DATA_FILE" using 3:4 index 5 with boxes fs solid 0.3 ls 6 title "STE",\
"GNUPLOT_DATA_FILE" using 3:5 index 5 with boxes fs solid 0.7 ls 6 notitle,\
"GNUPLOT_DATA_FILE" using 3:4 index 6 with boxes fs solid 0.3 ls 7 title "TK",\
"GNUPLOT_DATA_FILE" using 3:5 index 6 with boxes fs solid 0.7 ls 7 notitle,\
"GNUPLOT_DATA_FILE" using 3:4 index 7 with boxes fs solid 0.3 ls 8 title "TKL",\
"GNUPLOT_DATA_FILE" using 3:5 index 7 with boxes fs solid 0.7 ls 8 notitle,\
"GNUPLOT_DATA_FILE" using 3:4 index 8 with boxes fs solid 0.3 ls 9 title "Atypical",\
"GNUPLOT_DATA_FILE" using 3:5 index 8 with boxes fs solid 0.7 ls 9 notitle

#pause 9

