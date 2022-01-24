const {
	DynamoDBClient,
	PutItemCommand,
	PutItemInput,
} = require("@aws-sdk/client-dynamodb"); //

exports.handler = async (event) => {
	const { name, email } = event;

	const client = new DynamoDBClient({
		region: "us-east-1",
		apiVersion: "2012-08-10",
	});

	const command = new PutItemCommand({
		TableName: "nossatabela",
		Item: { name: { S: name }, email: { S: email } },
	});

	const response = await client.send(command);

	return response;
};

