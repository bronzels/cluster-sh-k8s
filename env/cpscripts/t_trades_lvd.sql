CREATE SCHEMA copytrading;
-- CREATE SCHEMA lxb_copytrading;
DROP TABLE IF EXISTS copytrading.t_trades_lvd;
CREATE TABLE copytrading.t_trades_lvd (
      _id varchar(128) NOT NULL,
      BrokerID integer NOT NULL,
      Account varchar(64) NOT NULL,
      TradeID integer NOT NULL,
      StandardSymbol varchar(64) DEFAULT NULL,
      Symbol varchar(64) DEFAULT NULL,
      Cmd integer DEFAULT NULL,
      BrokerLots DOUBLE PRECISION DEFAULT NULL,
      StandardLots DOUBLE PRECISION DEFAULT NULL,
      Swaps DOUBLE PRECISION DEFAULT NULL,
      Commission DOUBLE PRECISION DEFAULT NULL,
      OpenTime timestamp(3) DEFAULT NULL,
      CloseTime timestamp(3) DEFAULT NULL,
      Profit DOUBLE PRECISION DEFAULT NULL,
      Pips DOUBLE PRECISION DEFAULT NULL,
      Detail text DEFAULT NULL,
      UpdateTime timestamp(3) DEFAULT NULL,
      TraderBrokerID integer DEFAULT NULL,
      TraderAccount varchar(64) NULL DEFAULT NULL,
      TraderTradeID integer DEFAULT NULL,
      Status integer DEFAULT NULL,
      user_type integer DEFAULT NULL,
      mt4_server_name varchar(64) DEFAULT NULL,
      PRIMARY KEY(_id)
);

CREATE INDEX idx_copytrading_trades_account ON copytrading.t_trades_lvd (BrokerID, Account);
ALTER TABLE copytrading.t_trades_lvd REPLICA IDENTITY FULL;

-- docker 启动 pg 命令
-- docker run -d -it --name deb_postgres -v /data/docker/postgres:/var/lib/postgresql/data -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres debezium/postgres
