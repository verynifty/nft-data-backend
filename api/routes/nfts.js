var express = require("express");
var router = express.Router();

const {
  getNft,
  nftsInCollection,
  nftsByAccount,
  singleNftTransfers,
} = require("../controllers/nftsController");

router.get("/nft/:address/:id", getNft); //get a specific nft

router.get("/collection/nfts/:address", nftsInCollection); //get all nfts in a specific collection

router.get("/address/:address", nftsByAccount); //returns nfts owned by a wallet

router.get("/transfers/:address/:id", singleNftTransfers); //get transfers for specific nft
module.exports = router;
