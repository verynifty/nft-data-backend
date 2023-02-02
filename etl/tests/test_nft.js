ToolBox = new (require("../utils/toolbox"))();

process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0";

const sleep = (waitTimeInMs) =>
  new Promise((resolve) => setTimeout(resolve, waitTimeInMs));

(async () => {
  console.log("Will test");

  let TEST = new (require("../processors/nft"))(
    process.argv[2] || "0xe3435edbf54b5126e817363900234adfee5b3cee",
    process.argv[3] || "106"
  );
  await TEST.update(true);

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
