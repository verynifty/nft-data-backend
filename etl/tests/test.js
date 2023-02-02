require('dotenv').config()
let network = process.env.NETWORK == null ? 0 : parseInt(process.env.NETWORK)

const ethereum = new (require("../utils/ethereum"))(
  process.env.NFT20_INFURA
);

let ERC721ABI = require("../abis/erc721.json")
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

let FEATHER = new (require("../processors/collection"))(ethereum, storage, bucket, "0x51d0b69886dcde7a4fb9b39722868056804afbca")
let PUDGY = new (require("../processors/collection"))(ethereum, storage, bucket, "0xbd3531da5cf5857e7cfaa92426877b022e612cf8")
let SEWERRAT = new (require("../processors/collection"))(ethereum, storage, bucket, "0xd21a23606d2746f086f6528cd6873bad3307b903")
let HASHMASK = new (require("../processors/collection"))(ethereum, storage, bucket, "0xc2c747e0f7004f9e8817db2ca4997657a7746928")
let REVENANTS = new (require("../processors/collection"))(ethereum, storage, bucket, "0xc2d6b32e533e7a8da404abb13790a5a2f606ad75")
let TEST = new (require("../processors/collection"))(ethereum, storage, bucket, "0x51d0b69886dcde7a4fb9b39722868056804afbca")

const sleep = (waitTimeInMs) =>
  new Promise((resolve) => setTimeout(resolve, waitTimeInMs));

(async () => {



  await TEST.create()
  let events = await TEST.fill(13421947, 13421951)



})();
