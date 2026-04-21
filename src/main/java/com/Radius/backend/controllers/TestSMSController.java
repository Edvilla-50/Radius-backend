package com.Radius.backend.controllers;
import org.springframework.web.bind.annotation.*;
import com.Radius.backend.Services.SMSService;
@RestController
public class TestSMSController {
    private final SMSService smsService;
    public TestSMSController(SMSService smsService){
        this.smsService = smsService;
    }
    @GetMapping("/test-sms")
    public String testSms(){
        smsService.sendSms("+19157025002", "Test Message");
        return "SMS sent";
    }
}
