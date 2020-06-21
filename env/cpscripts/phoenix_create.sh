#!/bin/bash
IFS=
file=$(cat $1)
linesep="\n"
cmd_batch="!batch"
cmd_quit="!quit"
#toexec=$cmd_batch$linesep$file$linesep$cmd_batch$linesep$cmd_quit
toexec=$file$linesep$cmd_quit
echo -e $toexec | myphoenix.sh
