## Template file of Gnuplot script
##
## This template is used the Perl script "pk_fam_avg_seq_sim.pl"
## 

set terminal postscript eps enhanced color solid "Courier" 6

set title "Distribution of the Average Percent of Sequence Identity of PK domains\nacross Human PK families" font "Courier, 9"

##### setting axes #####
set tics out

set xtics autofreq nomirror    
set xlabel "Human Protein Kinase families" font "Courier, 9"
set nox2tics
set xtics (XTICS_LABELS)
set xtics rotate by 90

set ytics
set ylabel "Average Percent of Sequence Identity" font "Courier, 9"

set noy2tics
#set logscale y

set xrange [0:140]
set yrange [-1:110]
##### setting axes #####


set style line 1 lt rgb "red" lw 1
set style line 2 lt rgb "blue" lw 1  
set style line 3 lt rgb "green" lw 1
set style line 4 lt rgb "gold" lw 1
set style line 5 lt rgb "brown" lw 1
set style line 6 lt rgb "dark-blue" lw 1
set style line 7 lt rgb "dark-yellow" lw 1
set style line 8 lt rgb "orange" lw 1  
set style line 9 lt rgb "dark-green" lw 1  
set style line 10 lt rgb "dark-magenta" lw 1  
set boxwidth 1
set output "GNUPLOT.eps"

plot\
"GNUPLOT_DATA_FILE" using 3:4:4 index 0 with boxes fs solid 0.5 ls 1 title "AGC",\
"GNUPLOT_DATA_FILE" using 3:4:4 index 1 with boxes fs solid 0.5 ls 2 title "CAMK",\
"GNUPLOT_DATA_FILE" using 3:4:4 index 2 with boxes fs solid 0.5 ls 3 title "CK1",\
"GNUPLOT_DATA_FILE" using 3:4:4 index 3 with boxes fs solid 0.5 ls 4 title "CMGC",\
"GNUPLOT_DATA_FILE" using 3:4:4 index 4 with boxes fs solid 0.5 ls 5 title "Other",\
"GNUPLOT_DATA_FILE" using 3:4:4 index 5 with boxes fs solid 0.5 ls 6 title "RGC",\
"GNUPLOT_DATA_FILE" using 3:4:4 index 6 with boxes fs solid 0.5 ls 7 title "STE",\
"GNUPLOT_DATA_FILE" using 3:4:4 index 7 with boxes fs solid 0.5 ls 8 title "TK",\
"GNUPLOT_DATA_FILE" using 3:4:4 index 8 with boxes fs solid 0.5 ls 9 title "TKL",\
"GNUPLOT_DATA_FILE" using 3:4:4 index 9 with boxes fs solid 0.5 ls 10 title "Atypical"

#pause 9

