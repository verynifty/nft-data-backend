    module.exports = async (payload, helpers) => {
    console.log(`FillBlockRange :: Received ${JSON.stringify(payload)}`);
    ToolBox = new (require("../etl/utils/toolbox"))();
    ToolBox.params.erc721_metadata = false;
    ToolBox.params.erc1155_metadata = false;
    let startBlock = parseInt(payload.startBlock);
    let endBlock = parseInt(payload.endBlock);
    let steps = parseInt(payload.steps);
    while (startBlock < endBlock) {
        await ToolBox.processBlock(startBlock, startBlock + steps);
        startBlock = startBlock + steps;
    }  
};