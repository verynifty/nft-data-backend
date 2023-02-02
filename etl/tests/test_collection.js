
ToolBox = new (require("../utils/toolbox"))();

const sleep = (waitTimeInMs) =>
  new Promise((resolve) => setTimeout(resolve, waitTimeInMs));

(async () => {
  try {
    let Collection = new ToolBox.COLLECTION("0x4d15d2aaa891bfae0824f227f1ef1489cb4191ff")
    await Collection.create();
    await ToolBox.backFillAddress('0x4d15d2aaa891bfae0824f227f1ef1489cb4191ff')
  } catch (e) {
    console.log(e);
  }
})();
