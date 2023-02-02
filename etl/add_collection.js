require('dotenv').config()
let network = process.env.NETWORK == null ? 0 : parseInt(process.env.NETWORK)

const ethereum = new (require("./utils/ethereum"))(
    process.env.NFT20_INFURA
);

let ERC721ABI = require("./abis/erc721.json")
console.log(process.env.NFT20_DB_USER)

storage = new (require("./utils/postgres"))({
    user: process.env.PEPESEA_DB_USER,
    host: process.env.PEPESEA_DB_HOST,
    database: process.env.PEPESEA_DB_NAME,
    password: process.env.PEPESEA_DB_PASSWORD,
    port: parseInt(process.env.PEPESEA_DB_PORT),
    ssl: true,
    ssl: { rejectUnauthorized: false },
});

const sleep = (waitTimeInMs) =>
    new Promise((resolve) => setTimeout(resolve, waitTimeInMs));

(async () => {

    let address = process.argv[2]
    if (address == null) {
        console.error("Pass address of the collcetion as argument.")
        return;
    }
    let Collection = new (require("./processors/collection"))(ethereum, storage, bucket, address)
    await Collection.create()
    //let events = await Collection.fill(0, await ethereum.getLatestBlock())

})();
