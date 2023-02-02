require("dotenv").config();

(async () => {
  sleep = function (waitTimeInMs) {
    return new Promise((resolve) => setTimeout(resolve, waitTimeInMs));
  };

  console.log("Launching the refresh");
  try {

    let Client = new (require("./utils/postgres"))({
      user: process.env.NFT20_DB_USER,
      host: process.env.NFT20_DB_HOST,
      database: process.env.NFT20_DB_NAME,
      password: process.env.NFT20_DB_PASSWORD,
      port: parseInt(process.env.NFT20_DB_PORT),
      ssl: true,
      ssl: { rejectUnauthorized: false },
    });

    await Client.executeAsync(
      "REFRESH MATERIALIZED view CONCURRENTLY nft_collection_stats",
      {}
    );

    // const res = await Client.query(
    //   "CREATE INDEX idx_nft_update_at ON nft (updated_at)"
    // );

    // console.log("res ", res);
  } catch (error) {
    console.log(error);
    console.log("Timeout as expected");
  }
  console.log("SLEEP");
  await sleep(1000 * 60 * 15); // sleep 15 mins
  console.log("Slept");
})();
