package com.Radius.backend.Services;

import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;
import org.springframework.stereotype.Service;
import com.twilio.Twilio;

@Service
public class SMSService {

    private final String accountSid;
    private final String authToken;
    private final String messagingServiceSid;

    public SMSService() {
        this.accountSid = System.getenv("TWILIO_ACCOUNT_SID");
        this.authToken = System.getenv("TWILIO_AUTH_TOKEN");
        this.messagingServiceSid = System.getenv("TWILIO_MESSAGING_SERVICE_SID");

        Twilio.init(this.accountSid, this.authToken);
    }

    public String sendSms(String to, String body) {
        try {
            Message message = Message.creator(
                    new PhoneNumber(to),
                    messagingServiceSid,
                    body
            ).create();
            return "Sent: " + message.getSid();
        } catch (Exception e) {
            System.err.println("SMS failed: " + e.getMessage());
            return "Failed: " + e.getMessage();
        }
    }
}