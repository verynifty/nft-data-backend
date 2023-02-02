var express = require("express");
var router = express.Router();

const {
  collections,
  refreshCollection,
  getSingleCollection,
  getActivityCollection,
  getOwners,
  attributesInCollection,
  getTradedCollection,
} = require("../controllers/collectionsController");

router.get("/collections", collections); //get collections

router.get("/refresh/collection", refreshCollection); //refreshes collections

router.get("/collection/:address", getSingleCollection); //get a specific collection

router.get("/collection/owners/:address", getOwners);

router.get("/collection/attributes/:address", attributesInCollection); //get attrbiutes in a collection

router.get("/collection/activity/:address", getActivityCollection); // get latest transfers

router.get("/trades/collections", getTradedCollection); //get collections by trade activity

module.exports = router;
