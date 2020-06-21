#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
$p/stop-fmall.sh
$p/start-fmall.sh
