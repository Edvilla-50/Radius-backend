package com.Radius.backend.Data_Structres;

import jakarta.persistence.Entity;


public class TraitStack {
    public record TraitPopResult(String trait, int position) {}
    private TraitNode top;
    private int length;
    private int originalSize; 

    public TraitStack() {
        top = null;
        length = 0;
    }

    public void push(String trait){
        TraitNode node = new TraitNode(trait);

        node.next = top;
        top = node;

        length++;
        originalSize = length;
    }

    public TraitPopResult pop(){
        if(top == null){
            return null;
        }

        String trait = top.trait;
        int position = (originalSize - length)+1;

        top = top.next;
        length--;

        return new TraitPopResult(trait, position);
    }

    public String peek(){
        return top == null ? null : top.trait;
    }

    public int getLength(){
        return length;
    }
}
class TraitNode {

    String trait;
    TraitNode next;

    public TraitNode(String trait){
        this.trait = trait;
        this.next = null;
    }
}
