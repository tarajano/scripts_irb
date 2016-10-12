


set terminal postscript eps enhanced color solid "Courier" 8

set title "Lenghts of structural alignments" font "Courier, 14"

set size square

set noxtics
set noytics

set xtics autofreq nomirror    
set ytics autofreq nomirror

set nox2tics    
set noy2tics

set xlabel "dali" 
set ylabel "rapido" 

set output "dali_rapido_alilen.eps"

plot "dalilen_rapidolen.tab." using 1:2 notitle
