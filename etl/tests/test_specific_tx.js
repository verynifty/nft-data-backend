require("dotenv").config();
try {

    const ToolBox = new (require("../utils/toolbox"))();



    (async () => {
        let block = 13838674
        let contract = "0x495f947276749ce646f68ac8c248420045cb7b5e"

        console.log("Test specific block", block, contract)
        await ToolBox.processBlock(block, block, contract)
        latest_blocknumber++;



    })();

} catch (error) {
    console.log(error)
}