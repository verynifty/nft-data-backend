
ToolBox = new (require("../utils/toolbox"))();

process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0";

const sleep = (waitTimeInMs) =>
  new Promise((resolve) => setTimeout(resolve, waitTimeInMs));

(async () => {
  console.log("Will test");

  let missing = await ToolBox.storage.executeAsync(`	
  select timestamp, NOW() from nft_transfer nt where collection = '0x701a038af4bd0fc9b69a829ddcb2f61185a49568' and trade_marketplace is not null order by 1 DESC
  `)
  console.log(missing)


  console.log("Altered");
})();
