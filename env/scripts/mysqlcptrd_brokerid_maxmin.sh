#!/bin/bash

mysql -h 10.0.0.244 -P 3306 -u liuxiangbin -pm1njooUE04vc -e "SELECT MAX(brokerid) AS brokerid_max, MIN(brokerid) AS brokerid_min FROM copytrading.t_trades"
