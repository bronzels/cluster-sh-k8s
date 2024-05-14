db=$1
lag=$2
sleepsec=$3

~/scripts/mydwmongomscompareit.sh $db $lag $sleepsec 2> ~/fm/mydwmongomscompare_stderr.log > ~/fm/mydwmongomscompare_stdout.log &

