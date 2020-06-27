#!/usr/bin/env bash
currdir=$PWD

cd ${currdir}/env/cpscripts
tar -czvf ${currdir}/cpscripts.tar.gz *.*

cd ${currdir}/env/hbscripts
tar -czvf ${currdir}/hbscripts.tar.gz *.*

cd ${currdir}/env/scripts
tar -czvf ${currdir}/scripts.tar.gz *.*

cd ${currdir}/

