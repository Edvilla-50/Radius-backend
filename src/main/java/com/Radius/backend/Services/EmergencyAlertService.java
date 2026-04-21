/* 
package com.Radius.backend.Services;

@Service
public class EmergencyAlertService {

    private final SmsService smsService;

    public EmergencyAlertService(SmsService smsService) {
        this.smsService = smsService;
    }

    public void sendEmergencyAlert(User user, double lat, double lon, String note) {

        String googleMapsLink = "https://maps.google.com/?q=" + lat + "," + lon;

        String message = "🚨 EMERGENCY ALERT 🚨\n" +
                "User: " + user.getName() + "\n" +
                "Location: " + googleMapsLink + "\n" +
                "Note: " + note;

        if (user.getEmergencyPhoneOne() != null) {
            smsService.sendSms(user.getEmergencyPhoneOne(), message);
        }

        if (user.getEmergencyPhoneTwo() != null) {
            smsService.sendSms(user.getEmergencyPhoneTwo(), message);
        }
    }
}
    */
