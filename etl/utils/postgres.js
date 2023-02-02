require("dotenv").config();

pg = require("pg");
var knex = require("knex")({ client: "pg" });
var hstore = require("pg-hstore")();

function Writer(connectInfos) {
  if (connectInfos.query != null) {
    // This is an already instanciated pool
    this.pool = connectInfos;
  } else {
    // This is a connection info object
    // connectInfos.max = 3;
    this.pool = new pg.Pool(connectInfos);
  }
  this.knex = knex;
  this.hstore = hstore;
}

Writer.prototype.client = async function () {
  const client = await this.pool.connect();
  return client;
};

Writer.prototype.upsert = async function (type, obj, constraint) {
  //console.log('insert', type, obj);
  var query = this.knex(type)
    .insert(obj)
    .onConflict(constraint)
    .merge()
    .toString();
  // console.log(query)
  try {
    var res = await this.executeAsync(query);
    return true;
  } catch (error) {
    console.log(error);
    console.log("Error on insert");
  }
  return false;
};

Writer.prototype.insert = async function (type, obj) {
  //console.log('insert', type, obj);
  var query = this.knex(type).insert(obj).toString();
   console.log(query);
  try {
    var res = await this.executeAsync(query);
    return true;
  } catch (error) {
     console.log(error);
     console.log("Error on insert");
  }
  return false;
};

Writer.prototype.hstoreStringify = async function (items) {
  return await this.hstore.stringify(items);
};

Writer.prototype.hstoreParse = async function (hstoreItem) {
  return await this.hstore.parse(hstoreItem);
};

Writer.prototype.delete = async function (type, condition) {
  var query = this.knex(type).where(condition).del().toString();
  try {
    var res = await this.executeAsync(query);
    return true;
  } catch (error) {
  }
  return false;
};

Writer.prototype.update = async function (type, condition, values) {
  var query = this.knex(type).where(condition).update(values).toString();
  try {
    //console.log(query)
    var res = await this.executeAsync(query);
    return true;
  } catch (error) {
    console.log(error);
  }
  return false;
};

Writer.prototype.getAll = async function (type) {
  //  console.log('insert', type, obj);
  var query = this.knex(type).select("*").toString();
  var res = await this.executeAsync(query);
  return res;
};

Writer.prototype.getMax = async function (type, field, def = -Infinity) {
  var query = this.knex.max(field).from(type).toString();
  //  console.log(query)
  var res = await this.executeAsync(query);
  if (res != null && res[0] != null && res[0].max != null) {
    return parseInt(res[0].max);
  } else {
    return def;
  }
};

Writer.prototype.getMin = async function (type, field, def = Infinity) {
  var query = this.knex.min(field).from(type).toString();
  //  console.log(query)
  var res = await this.executeAsync(query);
  if (res != null && res[0] != null && res[0].min != null) {
    return parseInt(res[0].min);
  } else {
    return def;
  }
};

Writer.prototype.findOne = async function (type, conditions, select) {
  toSelect = select ? select : "*";
  var query = this.knex
    .select(toSelect)
    .where(conditions)
    .from(type)
    .toString();
  var res = await this.executeAsync(query);
  if (res != null && res[0] != null) {
    return res[0];
  } else {
    return null;
  }
};

Writer.prototype.executeAsync = async function (query) {
  var c = await this.client();
  //console.log(query)
  var res = null;
  try {
    res = await c.query(query);
  } catch (error) {
    c.release()
    throw error
    // never goes there if failed query
  } 
  c.release()
  return res.rows;
};

module.exports = Writer;
