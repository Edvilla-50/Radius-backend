package com.Radius.backend.Services;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;
import org.springframework.stereotype.Service;
import com.twilio.Twilio;


@Service

public class SMSService {
    public static final String ACCOUNT_SID = System.getenv("TWILIO_ACCOUNT_SID");
    public static final String AUTH_TOKEN = System.getenv("TWILIO_AUTH_TOKEN");
    public SMSService(){
        Twilio.init(ACCOUNT_SID, AUTH_TOKEN);
    }
    public String sendSms(String to, String body) {
    Message.creator(
        new PhoneNumber(to),
        new PhoneNumber("MG4bc11c5e1375d9ba0f1bb4c89e84fc76"),
        body).create();
        return "Msg sent";
    }
}
