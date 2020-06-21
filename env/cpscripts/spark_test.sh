#!/bin/bash
echo "!!!Usage: $0 <driver-memory(g)> <executor-memory(g)> <executor-cores>..."
echo driver-memory:$1
echo executor-memory:$2
echo executor-cores:$3

spark-submit --class org.apache.spark.examples.SparkPi \
    --master yarn \
    --deploy-mode client \
    --driver-memory "$1"g \
    --executor-memory "$2"g \
    --executor-cores "$3" \
    /app/hadoop/spark/examples/jars/spark-examples*.jar \
    10
