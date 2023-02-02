const { run, consoleLogFactory } = require("graphile-worker");
require("dotenv").config();
const pg = require("pg");

process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0";

if (process.argv.length < 4) {
    console.log(`Warning default arguments will be used:
    worker_launcher [NUMBER OF WORKER (10)] [Excluded jobs (None)]`)
}
const WORKER_NUMBER = process.argv.length > 2 ? parseInt(process.argv[2]) : 10;
const EXCLUDE_JOBS = process.argv.length > 3 ? [process.argv[3]] : null;

(async () => {

    console.log({
        WORKER_NUMBER: WORKER_NUMBER,
        EXCLUDE_JOBS: EXCLUDE_JOBS
    })
    
    const pool = new pg.Pool({
        user: process.env.NFT20_DB_USER,
        host: process.env.NFT20_DB_HOST,
        database: process.env.NFT20_DB_NAME,
        password: process.env.NFT20_DB_PASSWORD,
        port: process.env.NFT20_DB_PORT,
        max: WORKER_NUMBER + 1,
    });

    // Run a worker to execute jobs:
    const runner = await run({
        pgPool: pool,
        concurrency: WORKER_NUMBER,
        pollInterval: 1000,
        // you can set the taskList or taskDirectory but not both
        taskDirectory: `${__dirname}/tasks`,
        forbiddenFlags: EXCLUDE_JOBS
    });

    // Catch connection issues
    pool.on('error', async function (error, client) {
        console.log("Client might have been lost", error)
        await runner.stop();
    })

    // If the worker exits (whether through fatal error or otherwise), this
    // promise will resolve/reject:
    await runner.promise;

})();
