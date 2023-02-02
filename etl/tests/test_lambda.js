const { default: axios } = require("axios");
const axio = require("axios");

const NFTS_TO_INDEX = [
  {
    id: "198",
    address: "0x1a92f7381b9f03921564a437210bb9396471050c",
  },
  {
    id: "1858",
    address: "0x1a92f7381b9f03921564a437210bb9396471050c",
  },
  {
    id: "3290",
    address: "0x1a92f7381b9f03921564a437210bb9396471050c",
  },
  {
    id: "6060",
    address: "0x1a92f7381b9f03921564a437210bb9396471050c",
  },
];

for (const nft of NFTS_TO_INDEX) {
  console.log(nft);
  axios(
    `https://dooc96uco1.execute-api.us-east-1.amazonaws.com/dev/update/${nft.address}/${nft.id}?force=true`
  );
}
