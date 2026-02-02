package com.Radius.backend.Tests;

import com.vonage.client.VonageClient;
import com.vonage.client.sms.SmsSubmissionResponse;
import com.vonage.client.sms.messages.TextMessage;
import com.vonage.client.sms.MessageStatus;

public class Test {
    public static void main(String[] args){
        // Your API credentials
        String apiKey = "";            
        String apiSecret = "";  

        // Sender and recipient
        String from = "";             
        String to = ""; // recipient number with country code

        // The message you want to send
        String text = "You're a beautiful beagle!";

        // Build the client with correct credentials
        VonageClient client = VonageClient.builder()
                .apiKey(apiKey)
                .apiSecret(apiSecret)
                .build();

        // Create the text message using your "from" and "to" variables
        TextMessage message = new TextMessage(from, to, text);

        // Send the message
        SmsSubmissionResponse response = client.getSmsClient().submitMessage(message);

        // Check the response
        if (response.getMessages().get(0).getStatus() == MessageStatus.OK) {
            System.out.println("Message sent successfully.");
        } else {
            System.out.println("Message failed with error: " + response.getMessages().get(0).getErrorText());
        }
    }
}
