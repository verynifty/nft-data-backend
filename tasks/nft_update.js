
module.exports = async (payload, helpers) => {
    console.log(`NFTUpdate :: Received ${JSON.stringify(payload)}`);
    ToolBox = new (require("../etl/utils/toolbox"))();
    console.log(payload)
    let NFT = new ToolBox.NFT(payload.address, payload.tokenId);
    await NFT.update(payload.force);
};