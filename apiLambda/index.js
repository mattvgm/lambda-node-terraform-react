const { DynamoDBClient, PutItemCommand } = require("@aws-sdk/client-dynamodb"); //

exports.handler = async (event) => {
  //const { name, email } = event.body; <- Use without HTTP GW
  const { name, email } = JSON.parse(event.body); //<- Use WITH HTTP GW

  const client = new DynamoDBClient({
    region: process.env.REGION_NAME,
    apiVersion: "2012-08-10",
  });

  const command = new PutItemCommand({
    TableName: process.env.TABLE_NAME,
    Item: { name: { S: name }, email: { S: email } },
  });

  const response = await client.send(command);

  return response;
};
