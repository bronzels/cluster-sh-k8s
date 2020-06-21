#!/bin/bash
export JAVA_HOME=~/jdk;export PATH=~/jdk/bin:$PATH
~/presto-server/bin/presto-cli --server localhost:8070 --catalog kudu_without_emulation --schema default
