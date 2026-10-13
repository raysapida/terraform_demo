// A tiny message API. POST adds a message, GET lists them.
//
// Read what is NOT in this file: no endpoint, no region, no credentials, no
// table ARN. The table name comes from an environment variable Terraform sets.
// Everything else comes from the Lambda runtime — on real AWS from the execution
// role, on Floci from the AWS_ENDPOINT_URL it injects into the function. The
// same zip runs in both places unchanged.
//
// The AWS SDK v3 ships inside the nodejs22.x runtime, so there is no
// node_modules and no build step.
import { randomUUID } from "node:crypto";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand, ScanCommand } from "@aws-sdk/lib-dynamodb";

const db = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const TableName = process.env.TABLE_NAME;

const json = (statusCode, body) => ({
  statusCode,
  headers: { "content-type": "application/json" },
  body: JSON.stringify(body, null, 2),
});

// Errors from AWS (an AccessDenied from a missing IAM action, say) become a
// readable 500. Left unhandled, real AWS answers 502 and Floci answers 200 with
// the stack trace as the body — neither is what you want on a slide.
//
// One JSON log line per request. Lambda sends anything written to stdout or
// stderr to CloudWatch Logs, in the log group Terraform creates
// (/aws/lambda/<name>): `aws logs tail /aws/lambda/sacjs-lambda --follow`.
export const handler = async (event) => {
  const started = Date.now();
  const method = event.requestContext?.http?.method ?? "GET";
  let response;
  try {
    response = await route(event);
  } catch (error) {
    console.error(error);
    response = json(500, { error: error.name, message: error.message });
  }
  console.log(JSON.stringify({ method, status: response.statusCode, ms: Date.now() - started }));
  return response;
};

const route = async (event) => {
  const method = event.requestContext?.http?.method ?? "GET";

  if (method === "POST") {
    const raw = event.isBase64Encoded ? Buffer.from(event.body ?? "", "base64").toString() : event.body;
    let message;
    try {
      message = JSON.parse(raw || "{}").message;
    } catch {
      return json(400, { error: "body must be JSON" });
    }
    if (typeof message !== "string" || message.trim() === "") {
      return json(400, { error: 'send {"message": "..."}' });
    }

    const item = { id: randomUUID(), message: message.slice(0, 280), createdAt: new Date().toISOString() };
    await db.send(new PutCommand({ TableName, Item: item }));
    return json(201, item);
  }

  if (method === "GET") {
    // A Scan reads the whole table: fine for a demo table, a bill on a real one.
    const { Items = [] } = await db.send(new ScanCommand({ TableName }));
    Items.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    return json(200, { count: Items.length, messages: Items });
  }

  return json(405, { error: `${method} not allowed` });
};
