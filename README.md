# NFT data ETL

NFT data ETL by the [Muse DAO](https://musedao.io/) is an open source toolbox for indexing NFT transactions, sales and metadata on EVM compatible blockchains.

## Requirements

* A PostgreSQL compatible database
* NodeJS

## Installation

Clone repository 

```
git clone git@github.com:verynifty/nft-data-backend.git
cd nft-data-backend
```

Install dependencies

```
npm install
```

Add env variables:

```
touch .env
```

and edit with your own values:

```
PEPESEA_DB_USER=
PEPESEA_DB_HOST=
PEPESEA_DB_NAME=
PEPESEA_DB_PASSWORD=
PEPESEA_DB_PORT=

PEPESEA_RPC=
```

Create the DB tables by executing the content of the file:
```
etl/database_scripts/create_all.sql
```

![Database schema](https://github.com/verynifty/nft-data-backend/blob/main/table_summary.png?raw=true)


You can delete at anytime all the tables using:

```
etl/database_scripts/delete_all.sql
```

## Running

