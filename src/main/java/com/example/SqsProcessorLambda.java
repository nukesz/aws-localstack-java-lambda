package com.example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;

import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.PutItemRequest;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

public class SqsProcessorLambda implements RequestHandler<SQSEvent, Void> {

    @Override
    public Void handleRequest(SQSEvent event, Context context) {
        String tableName = System.getenv("TABLE_NAME");
        String endpoint  = System.getenv("ENDPOINT");
        String region    = System.getenv("REGION");

        try (DynamoDbClient dynamoDb = DynamoDbClient.builder()
                .endpointOverride(URI.create(endpoint))
                .build()) {

            for (SQSEvent.SQSMessage msg : event.getRecords()) {
                String body = msg.getBody();
                String hash = hashMessage(body);

                Map<String, AttributeValue> item = new HashMap<>();
                item.put("id", AttributeValue.builder().s(msg.getMessageId()).build());
                item.put("original", AttributeValue.builder().s(body).build());
                item.put("hash", AttributeValue.builder().s(hash).build());

                dynamoDb.putItem(PutItemRequest.builder()
                        .tableName(tableName)
                        .item(item)
                        .build());

                context.getLogger().log("Stored message: " + body + " with hash " + hash);
            }
        }
        return null;
    }

    private String hashMessage(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashedBytes = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hashedBytes);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
