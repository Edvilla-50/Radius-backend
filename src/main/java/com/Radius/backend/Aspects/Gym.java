package com.Radius.backend.Aspects;

public class Gym implements Interests{
    private String Name;
    private boolean con;
    private boolean con2;
    private boolean con3;
    private String diff;
    private String state;
    private String Time;
    @Override
    public void setOudoorsCond(boolean con){
        this.con = con;
    }
    @Override
    public String getName(){
        return this.Name;
    }
    @Override
    public void setDisAccesible(boolean con2){
        this.con2 = con2;
    }
    @Override
    public void setMoneyCond(boolean con3){
        this.con3 = con3;
    }
    @Override
    public void setDifficulty(String diff, String state){
        this.diff = diff;
        this.state = state;
    }
    @Override
    public void setMeetUpTime(String Time){
        this.Time = Time;
    }
}
