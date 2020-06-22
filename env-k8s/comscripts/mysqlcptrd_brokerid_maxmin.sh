#!/bin/bash

mysql -h ??? -P 3306 -u liuxiangbin -pm1njooUE04vc -e "SELECT MAX(brokerid) AS brokerid_max, MIN(brokerid) AS brokerid_min FROM copytrading.t_trades"
