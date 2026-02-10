package com.Radius.backend.Data_Structres;

import jakarta.persistence.Entity;


public class TraitStack {
    private TraitNode top;  
    private int length;//very important for dynamic formula

    public TraitStack(String trait){
        top = null;
        length =0;
    }
    public void push(String trait){
        TraitNode node = new TraitNode(trait);
        node.next = top; 
        top = node;    
        this.length++;
    }
    public String pop(){
        if(top == null){
            return null;
        }
        String trait = top.trait;
        top = top.next;
        this.length--;
        return trait;
    }
    public String peek(){
        return top.trait;
    }
    public int getLength(){
        return this.length;
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
