storage = new (require("../postgres"))({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: parseInt(process.env.DB_PORT),
  ssl: true,
  ssl: { rejectUnauthorized: false },
});

exports.liveStats = async (req, res, next) => {
  let current_day_transfers = await storage.executeAsync(
    `SELECT date_trunc('hour', CAST("public"."nft_transfer"."timestamp" AS timestamp)) AS "timestamp", sum(CASE WHEN "public"."nft_transfer"."from" = '0x0000000000000000000000000000000000000000' THEN 1 ELSE 0.0 END) AS "count_mint", sum(CASE WHEN ("public"."nft_transfer"."from" <> '0x0000000000000000000000000000000000000000'
              OR "public"."nft_transfer"."from" IS NULL) THEN 1 ELSE 0.0 END) AS "count_transfer"
          FROM "public"."nft_transfer"
          WHERE CAST("public"."nft_transfer"."timestamp" AS date) BETWEEN CAST((CAST(now() AS timestamp) + (INTERVAL '-1 day')) AS date)
             AND CAST(now() AS date)
          GROUP BY date_trunc('hour', CAST("public"."nft_transfer"."timestamp" AS timestamp))
          ORDER BY date_trunc('hour', CAST("public"."nft_transfer"."timestamp" AS timestamp)) ASC`
  );
  let current_week_transfers = await storage.executeAsync(
    `SELECT CAST("public"."nft_transfer"."timestamp" AS date) AS "timestamp", sum(CASE WHEN "public"."nft_transfer"."from" = '0x0000000000000000000000000000000000000000' THEN 1 ELSE 0.0 END) AS "count_mint", sum(CASE WHEN ("public"."nft_transfer"."from" <> '0x0000000000000000000000000000000000000000'
          OR "public"."nft_transfer"."from" IS NULL) THEN 1 ELSE 0.0 END) AS "count_transfer"
      FROM "public"."nft_transfer"
      WHERE CAST("public"."nft_transfer"."timestamp" AS date) BETWEEN CAST((CAST(now() AS timestamp) + (INTERVAL '-7 day')) AS date)
         AND CAST(now() AS date)
      GROUP BY CAST("public"."nft_transfer"."timestamp" AS date)
      ORDER BY CAST("public"."nft_transfer"."timestamp" AS date) ASC`
  );
  res.json({
    current_day_transfers: current_day_transfers,
    current_week_transfers: current_week_transfers,
  });
};

exports.activity = async (req, res, next) => {
  let query = storage.knex
    .select("*")
    .from("nft_transfer")
    .leftJoin("nft", {
      "nft_transfer.collection": "nft.address",
      "nft_transfer.token_id": "nft.token_id",
    })
    .orderBy("timestamp", "DESC")
    .orderBy("log_index", "DESC")
    .limit(100)
    .toString();
  console.log(query);
  let result = await storage.executeAsync(query);
  res.json(result);
};

exports.stream = async (req, res, next) => {
  const headers = {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
  };
  res.writeHead(200, headers);

  res.write(`msg: ${JSON.stringify("Streaming data")}\n\n`);

  let arr = [];
  // let startTime = new Date(Date.now() - 3000 * 60).toJSON();
  let interValID = setInterval(async () => {
    // console.log("start time: ", startTime);
    const query = storage.knex
      .select("*")
      .from("nft_transfer")
      .leftJoin("nft", {
        "nft_transfer.collection": "nft.address",
        "nft_transfer.token_id": "nft.token_id",
      })
      // .where("timestamp", ">", startTime)
      // .where("timestamp", "<", endTime)
      .orderBy("timestamp", "DESC")
      .limit(100)
      .toString();

    let result = await storage.executeAsync(query);
    arr = result;

    res.write(`data: ${JSON.stringify(arr)}\n\n`);

    // startTime = new Date(Date.now() - 1200 * 60).toJSON();

    // to end stream
    // if (xyz) {
    //   clearInterval(interValID);
    //   res.end();
    //   return;
    // }
  }, 10000);

  const clientId = Date.now();

  const newClient = {
    id: clientId,
    res,
  };

  clients.push(newClient);

  req.on("close", () => {
    console.log(`${clientId} Connection closed`);
    clients = clients.filter((client) => client.id !== clientId);
  });
};

exports.transactions = async (req, res, next) => {
  console.log(storage);
  let query = storage.knex
    .select("*")
    .from("nft_transfer")
    .limit(20)
    .toString();
  let result = await storage.executeAsync(query);
  res.json(result);
};

exports.totals = async (req, res, next) => {
  let totalIndexed = await storage.executeAsync(
    `select count(*) from nft where image is not null `
  );
  let totalNftsInDb = await storage.executeAsync(`select count(*) from nft`);

  res.json({
    total_nfts: totalNftsInDb,
    total_with_metadata: totalIndexed,
  });
};
