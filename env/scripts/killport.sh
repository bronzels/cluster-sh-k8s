#!/bin/bash
port=$1
kill -9 $(lsof -i:$port |awk '{print $2}' | tail -n 2)
