#!/bin/bash
export JAVA_HOME=~/jdk;export PATH=~/jdk/bin:$PATH
~/presto-server-2/bin/presto-cli --server localhost:8170 --catalog kudu_without_emulation --schema default
