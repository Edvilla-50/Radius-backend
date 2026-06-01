package com.Radius.backend.requests;

public class RegisterRequest {
    private String email;
    private String password;
    private String name;
    private String emergencyPhone;

    public String getEmail() { 
        return email; 
    }
    public String getPassword() { 
        return password; 
    }
    public String getName() { 
        return name; 
    }
    public String getEmergencyPhone() { 
        return emergencyPhone; 
    }
}