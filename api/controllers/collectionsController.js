storage = new (require("../postgres"))({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: parseInt(process.env.DB_PORT),
  ssl: true,
  ssl: { rejectUnauthorized: false },
});

exports.collections = async (req, res, next) => {
  console.log(process.env.DB_USER);
  let page =
    req.query.page != null && req.query.page != 0
      ? parseInt(req.query.page) - 1
      : 0;

  let addresses = req.query.address || [];

  console.log("addresses", addresses);

  let perPage = req.query.perPage != null ? parseInt(req.query.perPage) : 100;
  let period = req.query.period != null ? req.query.period : "hourly";

  console.log("type of ", typeof addresses);
  let query = storage.knex
    .select("*")
    .from("nft_collection_stats")
    .leftJoin("collection", {
      "collection.address": "nft_collection_stats.address",
    })
    .orderBy("transfers_" + period, "DESC")
    .limit(perPage)
    .offset(page * perPage)
    .modify(function (queryBuilder) {
      if (addresses.length > 0) {
        console.log(addresses);
        if (typeof addresses == "object") {
          for (var i = 0; i < addresses.length; i++) {
            if (i == 0) {
              queryBuilder.where("collection.address", addresses[0]);
            } else {
              queryBuilder.orWhere("collection.address", addresses[i]);
            }
          }
        } else {
          queryBuilder.where("collection.address", addresses);
        }
      }
    })
    .toString();

  let result = await storage.executeAsync(query);
  res.json(result);
};

exports.refreshCollection = async (req, res, next) => {
  await storage.executeAsync(
    "REFRESH MATERIALIZED view CONCURRENTLY nft_collection_stats"
  );
  res.json("ok");
};
exports.refreshCollection = async (req, res, next) => {
  await storage.executeAsync(
    "REFRESH MATERIALIZED view CONCURRENTLY nft_collection_stats"
  );
  res.json("ok");
};

exports.getSingleCollection = async (req, res, next) => {
  let collection = await storage.findOne("nft_collection_stats", {
    address: req.params.address.toLowerCase(),
  });
  res.json(collection);
};

exports.getActivityCollection = async (req, res, nex) => {
  let query = storage.knex
    .select("*")
    .from("nft_transfer")
    .where("nft_transfer.collection", req.params.address.toLowerCase())
    .leftJoin("nft", {
      "nft_transfer.collection": "nft.address",
      "nft_transfer.token_id": "nft.token_id",
    })
    .orderBy("timestamp", "DESC")
    .orderBy("log_index", "DESC")
    .limit(100)
    .toString();
  let result = await storage.executeAsync(query);
  res.json(result);
};

exports.getOwners = async (req, res, next) => {
  let query = storage.knex
    .raw(
      `
  SELECT "public"."nft"."owner" AS "address", count(*) AS "count"
  FROM "public"."nft"
  WHERE "public"."nft"."address" = ?
  GROUP BY "public"."nft"."owner"
  ORDER BY "count" DESC, "public"."nft"."owner" ASC
  `,
      [req.params.address.toLowerCase()]
    )
    .toString();
  let result = await storage.executeAsync(query);
  res.json({ owners: result });
};

exports.attributesInCollection = async (req, res, next) => {
  let query = storage.knex
    .raw(
      `select "key",  json_agg(json_build_object(value, count)) AS attributes from (SELECT key, value, count(*)  FROM
      (SELECT (each("attributes")).key,  (each("attributes")).value FROM  nft where nft.address = ?) AS stat
      GROUP BY key, value 
     , key  ORDER BY count DESC) as temporary group by "key" `,
      [req.params.address.toLowerCase()]
    )
    .toString();
  let result = await storage.executeAsync(query);
  res.json(result);
};

exports.getTradedCollection = async (req, res, next) => {
  let addresses = req.query.address || [];

  let order = req.query.orderBy;
  let orderBy = {
    volume_hour: "(trades_current_hour->>'volume')::numeric",
    volume_day: "(trades_current_day->>'volume')::numeric",
    volume_week: "(trades_current_week->>'volume')::numeric",
    volume_month: "(trades_current_month->>'volume')::numeric",
    buyers_hour: "(trades_current_hour->>'buyers')::numeric",
    buyers_day: "(trades_current_day->>'buyers')::numeric",
    buyers_week: "(trades_current_week->>'buyers')::numeric",
    buyers_month: "(trades_current_month->>'buyers')::numeric",
    sellers_hour: "(trades_current_hour->>'sellers')::numeric",
    sellers_day: "(trades_current_day->>'sellers')::numeric",
    sellers_week: "(trades_current_week->>'sellers')::numeric",
    sellers_month: "(trades_current_month->>'sellers')::numeric",
    trades_hour: "(trades_current_hour->>'trades')::numeric",
    trades_day: "(trades_current_day->>'trades')::numeric",
    trades_week: "(trades_current_week->>'trades')::numeric",
    trades_week: "(trades_current_month->>'trades')::numeric",
    max_price_hour: "(trades_current_hour->>'max_price')::numeric",
    max_price_day: "(trades_current_day->>'max_price')::numeric",
    max_price_week: "(trades_current_week->>'max_price')::numeric",
    max_price_month: "(trades_current_month->>'max_price')::numeric",
    min_price_hour: "(trades_current_hour->>'min_price')::numeric",
    min_price_day: "(trades_current_day->>'min_price')::numeric",
    min_price_week: "(trades_current_week->>'min_price')::numeric",
    min_price_month: "(trades_current_month->>'min_price')::numeric",
    median_price_hour: "(trades_current_hour->>'median_price')::numeric",
    median_price_day: "(trades_current_day->>'median_price')::numeric",
    median_price_week: "(trades_current_week->>'median_price')::numeric",
    median_price_month: "(trades_current_month->>'median_price')::numeric",
  };
  let sort = orderBy["volume_day"];
  if (order != null && orderBy[order] != null) {
    sort = orderBy[order];
  }
  let perPage = req.query.perPage != null ? parseInt(req.query.perPage) : 20;
  let page =
    req.query.page != null && req.query.page != 0
      ? parseInt(req.query.page) - 1
      : 0;

  let query = storage.knex
    .select("*")
    .from("nft_collection_stats")
    .leftJoin("collection", {
      "nft_collection_stats.address": "collection.address",
    })

    .orderByRaw(`${sort} DESC  NULLS LAST`)
    .limit(perPage)
    .offset(page * perPage)
    .modify(function (queryBuilder) {
      if (addresses.length > 0) {
        console.log(addresses);
        if (typeof addresses == "object") {
          for (var i = 0; i < addresses.length; i++) {
            if (i == 0) {
              queryBuilder.where("nft_collection_stats.address", addresses[0]);
            } else {
              queryBuilder.orWhere(
                "nft_collection_stats.address",
                addresses[i]
              );
            }
          }
        } else {
          queryBuilder.where("nft_collection_stats.address", addresses);
        }
      }
    })

    .toString();

  try {
    let result = await storage.executeAsync(query);
    res.json({
      collections: result,
      query: query,
      page: page,
      perPage: perPage,
    });
  } catch (error) {
    res.json({
      error: error,
      query: query,
      page: page,
      perPage: perPage,
    });
  }
};
