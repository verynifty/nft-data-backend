opensea = require("../processors/opensea")

process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0";

const sleep = (waitTimeInMs) =>
  new Promise((resolve) => setTimeout(resolve, waitTimeInMs));

(async () => {
    console.log(opensea)
    OS = new opensea();
    await OS.getSales()
})();
