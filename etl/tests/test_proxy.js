require('dotenv').config()
let network = process.env.NETWORK == null ? 0 : parseInt(process.env.NETWORK)

const ethereum = new (require("../utils/ethereum"))(
  process.env.NFT20_INFURA
);

let ERC721ABI = require("../abis/erc721.json");
const ToolBox = require('../utils/toolbox');
console.log(process.env.NFT20_DB_USER)

storage = new (require("../utils/postgres"))({
  user: process.env.NFT20_DB_USER,
  host: process.env.NFT20_DB_HOST,
  database: "verynifty",
  password: process.env.NFT20_DB_PASSWORD,
  port: 25061,
  ssl: true,
  ssl: { rejectUnauthorized: false },
}); 

bucket = new (require("../utils/bucket"))({
  endpoint: process.env.BUCKET_ENDPOINT,
  accessKeyId: process.env.BUCKET_KEY,
  secretAccessKey: process.env.BUCKET_SECRET,
  bucket_name: process.env.BUCKET_NAME
});

const t = new ToolBox();

let Proxy = new (require("../processors/collection"))(ethereum, storage, bucket, "0xd533a949740bb3306d119cc777fa900ba034cd52")

const sleep = (waitTimeInMs) =>
  new Promise((resolve) => setTimeout(resolve, waitTimeInMs));

(async () => {


  await Proxy.create()



})();
