const express = require("express");
const cors = require("cors");

require("dotenv").config({ path: __dirname + "/.env" });

const { quickAddJob } = require("graphile-worker");

const app = express();
const port = 3000;

app.use(cors());

const storage = require("./storage.js");

function isAddress(address) {
  return address.startsWith("0x") && address.lenght == 42;
}

var collectionsRouter = require("./routes/collections");
var nftsRouter = require("./routes/nfts");
var statsController = require("./routes/stats");

app.use("/", collectionsRouter);
app.use("/", nftsRouter);
app.use("/", statsController);

app.get("/test", async function (req, res) {
  console.log("calling");
  try {
    let query = await storage.knex.select("*").from("collection").toString();

    let result = await storage.executeAsync(query);
    res.json(result);
  } catch (e) {
    console.log(e);
  }
});

app.get("/forcerefresh/:address", async function (req, res) {
  let reset = storage.knex
    .raw(
      `
  update "collection" set "default_image" = NULL, nft_data_base_url = NULL, nft_image_base_url = NULL  where "address" = ? 
  `,
      [req.params.address.toLowerCase()]
    )
    .toString();
  await storage.executeAsync(reset);
  let query = storage.knex
    .raw(
      `SELECT graphile_worker.add_job(
        'nft_update',
        json_build_object(
          'address', address,
          'tokenId', token_id::TEXT,
          'force', TRUE
        ),
        job_key := CONCAT('nftupdate_', address, '_', token_id), job_key_mode := 'preserve_run_at'
      ) from (select * from nft where address = ?  ) u
      `,
      [req.params.address.toLowerCase()]
    )
    .toString();
  let r = await storage.executeAsync(query);
  res.json("ok");
});

let clients = [];

// new search
app.get("/search/", async function (req, res) {
  const limit = req.query.limit ? req.query.limit : 10;

  let query = storage.knex
    .raw(
      `SELECT c.address, c.name, c.symbol, c.default_image , c.slug, c.type from collection c, nft_collection_stats s where c.address = s.address AND (c."type" = 721 OR c."type" = 1155) and (c.name ilike ? or c.symbol ilike ? or c.address = ?) ORDER BY (trades_current_week->>'volume')::numeric DESC  NULLS LAST LIMIT ?`,
      [
        "%" + req.query.s.toLocaleLowerCase() + "%",
        "%" + req.query.s.toLocaleLowerCase() + "%",
        req.query.s.toLowerCase(),
        limit,
      ]
    )
    .toString();

  let collections = await storage.executeAsync(query);

  collections = collections.map(function (item) {
    if (item.default_image) {
      const url = new URL(item.default_image);
      item.default_image = `${url.origin}/50x50${url.pathname}`;
    }
    return item;
  });

  let querynft = storage.knex
    .raw(
      `select * from nft where  name ilike ? order by updated_at desc LIMIT ${limit}`,
      ["%" + req.query.s + "%"]
    )
    .toString();
  let nfts = await storage.executeAsync(querynft);

  nfts = nfts.map(function (item) {
    if (item.image) {
      const url = new URL(item.image);
      item.image = `${url.origin}/50x50${url.pathname}`;
    }
    return item;
  });

  res.json({
    collections,
    nfts,
  });
});

app.get("/search/nft/", async function (req, res) {
  const limit = req.query.limit ? req.query.limit : 10;
  let query = storage.knex
    .raw(
      `select address, name, symbol, default_image , slug, type from collection c where (c."type" = 721 OR c."type" = 1155) and (c.name ilike ? or symbol ilike ? or address = ?) LIMIT ?`,
      [
        "%" + req.query.s + "%",
        "%" + req.query.s + "%",
        req.query.s.toLowerCase(),
        limit,
      ]
    )
    .toString();

  let collections = await storage.executeAsync(query);

  collections = collections.map(function (item) {
    if (item.default_image) {
      const url = new URL(item.default_image);
      item.default_image = `${url.origin}/50x50${url.pathname}`;
    }
    return item;
  });

  let querynft = storage.knex
    .raw(
      `select * from nft where  name ilike ? order by updated_at desc LIMIT ${limit}`,
      ["%" + req.query.s + "%"]
    )
    .toString();
  let nfts = await storage.executeAsync(querynft);

  nfts = nfts.map(function (item) {
    if (item.image) {
      const url = new URL(item.image);
      item.image = `${url.origin}/50x50${url.pathname}`;
    }
    return item;
  });

  res.json({
    collections,
    nfts,
  });
});

app.get("/", async function (req, res) {
  res.json({ HELLO: true });
});

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`);
});

module.exports = app;
