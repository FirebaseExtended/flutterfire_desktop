require("dotenv").config();

const fs = require("fs");
const express = require("express");
const bodyParser = require("body-parser");
const { JSONRPCServer } = require("json-rpc-2.0");
const { initializeApp } = require("firebase-admin/app");
const { getStorage } = require("firebase-admin/storage");
const { basename } = require("path");

const fbApp = initializeApp({
  storageBucket: "flutterfire-e2e-tests.appspot.com",
});

const storage = getStorage(fbApp);
const bucket = storage.bucket();

const logMiddleware = (next, request, serverParams) => {
  console.log(`Received ${JSON.stringify(request)}`);

  return next(request, serverParams).then((response) => {
    console.log(`Responding ${JSON.stringify(response)}`);
    return response;
  });
};

const server = new JSONRPCServer();
server.applyMiddleware(logMiddleware);

server.addMethod("clearStorage", async () => {
  await bucket.deleteFiles({ prefix: "" });
});

server.addMethod("uploadFile", async ({ path }) => {
  await new Promise((resolve, reject) => {
    const r = fs.createReadStream(path);

    const upload = () => {
      const w = bucket.file(basename(path)).createWriteStream();
      r.pipe(w);

      w.on("finish", resolve);
      w.on("error", reject);
    };

    r.on("error", reject);
    r.on("ready", upload);
  });
});

server.addMethod("verifyMD5Hash", async ({ path, hash }) => {
  const file = bucket.file(path);
  const [metadata] = await file.getMetadata();

  if (metadata.md5Hash !== hash) {
    throw new Error(`MD5 hash mismatch for ${path}`);
  }
});

server.addMethod("putString", async ({ path, content }) => {
  const file = bucket.file(path);
  await file.save(content);
});

server.addMethod("verifyExists", async ({ path }) => {
  const file = bucket.file(path);
  const [exists] = await file.exists();
  if (!exists) {
    throw new Error(`File ${path} does not exist`);
  }
});

server.addMethod("putMetadata", async ({ path, metadata }) => {
  const file = bucket.file(path);
  await file.setMetadata(metadata);
});

server.addMethod("getMetadata", async ({ path }) => {
  const file = bucket.file(path);
  const [metadata] = await file.getMetadata();
  return metadata;
});

const app = express();
app.use(bodyParser.json());

app.post("/json-rpc", (req, res) => {
  const jsonRPCRequest = req.body;
  server.receive(jsonRPCRequest).then((jsonRPCResponse) => {
    if (jsonRPCResponse) {
      res.json(jsonRPCResponse);
    } else {
      res.sendStatus(204);
    }
  });
});

app.listen(4040, () => {
  console.log("JSON-RPC server listening on port 4040");
});
