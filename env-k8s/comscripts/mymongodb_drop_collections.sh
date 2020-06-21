#!/bin/bash
db=$1
table=$2
mongo --username root --password 'rootRoot!@#' --authenticationDatabase admin --host ??? --port ??? --eval "db=db.getSiblingDB('$db'); db.$table.drop();"

