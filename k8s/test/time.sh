#!/bin/bash
###########################################################
#  description: get msec level time delay                 #
#  author     : 骏马金龙                                   #
#  blog       : http://www.cnblogs.com/f-ck-need-u/       #
########################################################### timediff() {start_time=$end_time=$
    start_s=${start_time%.*}
    start_nanos=${start_time#*.}
    end_s=${end_time%.*}
    end_nanos=${end_time#*.}     [  -lt  ];end_s=$(( #$end_s -  ))
        end_nanos=$(( #$end_nanos + ** ))=$(( #$end_s - #$start_s )).`printf "%03d\n" $(( (#$end_nanos - #$start_nanos)/** ))`     $}
start=1502758855.907197692
end=1502758865.066894173
timediff $start $end
