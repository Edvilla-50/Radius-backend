package com.Radius.backend.Aspects;


public interface Interests {

    public String getName();
    public void setOudoorsCond(boolean con);//all hobby classes must have these methods,
    public void setDisAccesible(boolean con2);//if the hobby is accisble to people of disabilty
    public void setMoneyCond(boolean con3);//does the hobby require moneh?
    public void setDifficulty(String diff, String state);//how hard if the hobby, in any sense (mentally, physically,etc) 
    public void setMeetUpTime(String Time);//meetup time
}
