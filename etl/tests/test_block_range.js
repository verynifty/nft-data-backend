
ToolBox = new (require("../utils/toolbox"))();

process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0";

const sleep = (waitTimeInMs) =>
  new Promise((resolve) => setTimeout(resolve, waitTimeInMs));

(async () => {
  try {

    await ToolBox.processBlock(
      14389701,
      14389701)
    // await ToolBox.processBlock(14349908, 14349908 )

   // await ToolBox.processBlock(14346682, 14346682 )
    console.log("Tested");
  } catch (error) {
    console.log(error)
  }

})();
