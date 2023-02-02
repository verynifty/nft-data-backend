storage = new (require("../utils/postgres"))({
  user: process.env.NFT20_DB_USER,
  host: process.env.NFT20_DB_HOST,
  database: "verynifty",
  password: process.env.NFT20_DB_PASSWORD,
  port: 25061,
  ssl: true,
  ssl: { rejectUnauthorized: false },
});

const sleep = (waitTimeInMs) =>
  new Promise((resolve) => setTimeout(resolve, waitTimeInMs));

const { awsmobile } = require("../../src/aws-custom");

const AmplifyCore = require("aws-amplify");
const Amplify = require("aws-amplify").default;
const { API } = Amplify;
Amplify.configure(awsmobile);

let force = false;

(async () => {
  let query = storage.knex
    .raw(
      `select address, token_id from nft where nft.created_at >= '2022-01-14 06:00:00' and  image is  null`
    )
    .toString();
  let result = await storage.executeAsync(query);
  console.log("About to run total failed:", result.length);
  for (const nft of result) {
    console.log(`indexing ${nft.address}:${nft.token_id}`);

    try {
      await API.get(
        "metadataApi",
        `/update/${nft.address}/${nft.token_id}?force=${force}`
      );
    } catch (error) {
      console.log("Lambda crashed");
      console.log(error);
    }
  }
})();
