const ToolBox = new (require("../utils/toolbox"))();

process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0";

const sleep = (waitTimeInMs) =>
  new Promise((resolve) => setTimeout(resolve, waitTimeInMs));

(async () => {
 

    const ToolBox = new (require("../utils/toolbox"))();
    let Collection = new (require("../processors/collection"))(ToolBox, "0x10e0271ec47d55511a047516f2a7301801d55eab");
    await Collection.create()
    console.log(Collection.backfilled)
    if (Collection.backfilled) {
      await Collection.fillAndProcess(0, Collection.firstBlockSeen);
      await Collection.setBackFilled(true);
    }


})();




