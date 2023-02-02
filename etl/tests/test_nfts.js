ToolBox = new (require("../utils/toolbox"))();

process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0";

const sleep = (waitTimeInMs) =>
  new Promise((resolve) => setTimeout(resolve, waitTimeInMs));

(async () => {
  console.log("Will test");

  const storage = new (require("../utils/postgres"))({
    user: process.env.PEPESEA_DB_USER,
    host: process.env.PEPESEA_DB_HOST,
    database: process.env.PEPESEA_DB_NAME,
    password: process.env.PEPESEA_DB_PASSWORD,
    port: parseInt(process.env.PEPESEA_DB_PORT),
    ssl: true,
    ssl: { rejectUnauthorized: false },
  });
  
  let query = storage.knex
    .raw(
      `select address, token_id from nft WHERE  image is  null`
    )
    .toString();
  let result = await storage.executeAsync(query);
  console.log("About to run total failed:", result.length);
  for (const nft of result) {
    let TEST = new (require("../processors/nft"))(
      nft.address,
      nft.token_id
    );
    await TEST.update(true);
  }

  // do loop

  // for (i = 0; i <= nfts.length; i++) {
  //   try {
  //     let TEST = new (require("../processors/nft"))(
  //       nfts[i].address,
  //       nfts[i].token_id
  //     );

  //     await TEST.update(true);

  //     console.log(
  //       `fully indexed address: ${nfts[i].address} token_id ${nfts[i].token_id}`
  //     );
  //   } catch (e) {
  //     console.log(e);

  //     console.log(
  //       `Error indexing address: ${nfts[i].address} token_id ${nfts[i].token_id}`
  //     );
  //   }
  // }

  console.log("Tested");
})();
