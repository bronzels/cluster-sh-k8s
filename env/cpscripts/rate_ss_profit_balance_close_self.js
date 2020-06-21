db.mg_result_all.find({"$and":[{"rate_ss_profit_balance_close_self":{$gt:0.00}},{"rate_ss_profit_balance_close_self":{$lt:100000}}],rate_ss_profit_balance_close_follow:{$exists: true}},
    {login:1,brokerid:1,rate_ss_profit_balance_close_follow:1,rate_ss_profit_balance_close_self:1,rate_ss_profit_balance_close:1}).forEach(function(record){
    print(record.brokerid+","+record.login.valueOf()+","+record.rate_ss_profit_balance_close_follow + "," + record.rate_ss_profit_balance_close_self + "," + record.rate_ss_profit_balance_close);
});
