const storage = new (require("../etl/utils/postgres"))({
  user: process.env.PEPESEA_DB_USER,
  host: process.env.PEPESEA_DB_HOST,
  database: process.env.PEPESEA_DB_NAME,
  password: process.env.PEPESEA_DB_PASSWORD,
  port: parseInt(process.env.PEPESEA_DB_PORT),
  ssl: true,
  ssl: { rejectUnauthorized: false },
});

module.exports = storage;
