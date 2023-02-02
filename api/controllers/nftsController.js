storage = new (require("../postgres"))({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: parseInt(process.env.DB_PORT),
  ssl: true,
  ssl: { rejectUnauthorized: false },
});

exports.getNft = async (req, res, next) => {
  let item = await storage.findOne("nft", {
    address: req.params.address.toLowerCase(),
    token_id: req.params.id.toLowerCase(),
  });
  res.json(item);
};

exports.nftsInCollection = async (req, res, next) => {
  let page = req.query.page != null ? parseInt(req.query.page) : 0;
  let perPage = req.query.perPage ? req.query.perPage : 20;
  let query = storage.knex
    .select("*")
    .from("nft")
    .where({ address: req.params.address.toLowerCase() })
    .orderBy("latest_block_number", "DESC")
    .orderBy("image")
    .limit(perPage)
    .offset(page * perPage);

  if (req.query.attributes != null) {
    console.log(req.query.attributes);
    let attrs = JSON.parse(decodeURI(req.query.attributes));
    for (const key in attrs) {
      if (Object.hasOwnProperty.call(attrs, key)) {
        query = query.whereRaw(
          `attributes -> ? in (` + attrs[key].map((_) => "?").join(",") + `)`,
          [key, ...attrs[key]]
        );
      }
    }
  }
  query = query.toString();
  let result = await storage.executeAsync(query);
  res.json(result);
};

exports.nftsByAccount = async (req, res, next) => {
  let query;
  let page =
    req.query.page != null && req.query.page != 0
      ? parseInt(req.query.page) - 1
      : 0;
  let perPage = req.query.perPage ? req.query.perPage : 20;

  let addresses = req.query.address || [];

  query = storage.knex
    .select([
      "nft.address",
      "nft.token_id",
      "nft.name",
      "nft.description",
      "nft.external_url",
      "nft.image",
      "nft.attributes",
      "nft.image_type",
      "nft.owner",
      "nft.created_at",
      "nft.updated_at",
      "nft.latest_block_number",
      storage.knex.raw(`"collection"."name" as "collection_name"`),
      storage.knex.raw(`"collection"."symbol" as "collection_symbol"`),
    ])

    .modify(function (queryBuilder) {
      if (addresses.length > 0) {
        if (typeof addresses == "object") {
          console.log("here");
          for (var i = 0; i < addresses.length; i++) {
            if (i == 0) {
              queryBuilder.where("nft.address", addresses[0]);
              queryBuilder.andWhere(
                "nft.owner",
                req.params.address.toLowerCase()
              );
            } else {
              queryBuilder.orWhere("nft.address", addresses[i]);
              queryBuilder.andWhere(
                "nft.owner",
                req.params.address.toLowerCase()
              );
            }
          }
        } else {
          queryBuilder.where("nft.address", addresses);
        }
      }
    })
    .where({
      "nft.owner": req.params.address.toLowerCase(),
    })
    .leftJoin("collection", "nft.address", "collection.address")
    .orderBy("latest_block_number", "DESC")
    .from("nft")
    .limit(perPage)
    .offset(page * perPage);
  if (req.query.collection != null) {
    query = query.where("nft.address", req.query.collection.toLowerCase());
  }
  if (req.query.attributes != null) {
    console.log(req.query.attributes);
    let attrs = JSON.parse(decodeURI(req.query.attributes));
    for (const key in attrs) {
      if (Object.hasOwnProperty.call(attrs, key)) {
        query = query.whereRaw(
          `attributes -> ? in (` + attrs[key].map((_) => "?").join(",") + `)`,
          [key, ...attrs[key]]
        );
      }
    }
  }
  query = query.toString();
  let result = await storage.executeAsync(query);
  res.json(result);
};

exports.singleNftTransfers = async (req, res, next) => {
  let condition = {
    "nft_transfer.collection": req.params.address.toLowerCase(),
    "nft_transfer.token_id": req.params.id.toLowerCase(),
  };
  let query = storage.knex
    .select("*")
    .from("nft_transfer")
    .leftJoin("nft", {
      "nft_transfer.collection": "nft.address",
      "nft_transfer.token_id": "nft.token_id",
    })
    .orderBy("timestamp", "DESC")
    .where(condition)
    .limit(100)
    .toString();
  let result = await storage.executeAsync(query);
  res.json(result);
};
