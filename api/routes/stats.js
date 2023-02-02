var express = require("express");
var router = express.Router();

const {
  liveStats,
  activity,
  stream,
  transactions,
  totals,
} = require("../controllers/statsController.js");

router.get("/stats/live", liveStats); //get liveStats
router.get("/activity", activity); //activity

// this keeps open stream of activity, we can develop it further later
// todo make sure time calculation makes sense after and adde where timestamp to query
router.get("/stream", stream); //stream

router.get("/transactions", transactions);

// get total idnexed
router.get("/totals", totals);

module.exports = router;
