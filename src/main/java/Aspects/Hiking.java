package Aspects;

public class Hiking implements Interests{
   public String name ="Hiking";
   public boolean moneyneeded = false;
   public boolean disAccesible = false;
   public String diff = "";
   public String time = "";
   @Override
   public void setOudoorsCond(boolean con){
    this.moneyneeded = con;
   }
   @Override
   public void setDisAccesible(boolean con2){
        this.disAccesible = con2;
   }
   @Override
   public void setDifficulty(String diff){
        if(diff.equals("Easy")||diff.equals("Medium")|| diff.equals("Hard")){
            this.diff = diff;
        }
   }
   @Override
   public void setMeetUpTime(String time){
    this.time = time;
   }    
   public void setMoneyCond(boolean con3){
    this.moneyneeded = con3;
   }
}
