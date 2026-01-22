package com.Radius.backend.Aspects;


public class Reading implements Interests{//Reddit ahh class name
   public String name ="Reading";
   public boolean moneyneeded = true;
   public boolean disAccesible = true;
   public String diff = "";
   public String time = "";
   public String state = "";
   @Override
   public void setOudoorsCond(boolean con){//setters and getters vro
    this.moneyneeded = con;
   }
   @Override
   public void setDisAccesible(boolean con2){
        this.disAccesible = con2;
   }
   @Override
   public void setDifficulty(String diff, String state){
        if(diff.equals("Easy")||diff.equals("Medium")|| diff.equals("Hard")){//tight constraints, but it should be more optimal really
            this.diff = diff;
        }
        this.state = state;
   }
   @Override
   public void setMeetUpTime(String time){//also not the most optimal, I should try changing this
    this.time = time;
   }    
   @Override
   public void setMoneyCond(boolean con3){
    this.moneyneeded = con3;
   }
}

