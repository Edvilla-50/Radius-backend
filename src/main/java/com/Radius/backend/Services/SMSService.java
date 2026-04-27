package com.Radius.backend.Services;

import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;
import org.springframework.stereotype.Service;
import com.twilio.Twilio;

@Service
public class SMSService {

    public static final String ACCOUNT_SID = System.getenv("TWILIO_ACCOUNT_SID");
    public static final String AUTH_TOKEN = System.getenv("TWILIO_AUTH_TOKEN");

    private static final String MESSAGING_SERVICE_SID = "MG1d7566df91520a0533beda03c34d57ef";

    public SMSService() {
        Twilio.init(ACCOUNT_SID, AUTH_TOKEN);
    }

    public String sendSms(String to, String body) {
        Message.creator(
                new PhoneNumber(to),
                MESSAGING_SERVICE_SID,   // <-- correct usage
                body
        ).create();
        return "Msg sent";
    }
}
