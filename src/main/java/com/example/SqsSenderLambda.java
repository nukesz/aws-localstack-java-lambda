package com.example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;
import software.amazon.awssdk.services.sqs.model.SendMessageResponse;

public class SqsSenderLambda implements RequestHandler<String, String> {

    private final SqsClient sqsClient = SqsClient.builder()
            .endpointOverride(java.net.URI.create(System.getenv("SQS_ENDPOINT"))) // for LocalStack
            .region(software.amazon.awssdk.regions.Region.US_EAST_1)
            .build();

    private final String queueUrl = System.getenv("QUEUE_URL");

    @Override
    public String handleRequest(String input, Context context) {
        SendMessageRequest request = SendMessageRequest.builder()
                .queueUrl(queueUrl)
                .messageBody("Message from Lambda: " + input)
                .build();

        SendMessageResponse response = sqsClient.sendMessage(request);
        return "Sent message with ID: " + response.messageId();
    }
}
