package com.Radius.backend.Data_Structres;

public class TraitStack {
    private TraitNode top;  

    public TraitStack(String trait){
        top = null;
    }
    public void push(String trait){
        TraitNode node = new TraitNode(trait);
        node.next = top; 
        top = node;    
    }
    public String pop(){
        if(top == null){
            return null;
        }
        String trait = top.trait;
        top = top.next;
        return trait;
    }
    public String peek(){
        return top.trait;
    }
}
class TraitNode{
    String trait;
    TraitNode next;
    public TraitNode(String trait){
        this.trait = trait;
        this.next = null;
    }
}
