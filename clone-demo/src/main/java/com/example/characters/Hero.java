package com.example.characters;


import com.example.utils.MathUtils;
import com.example.utils.RandomUtils;


public class Hero {
    private String name;
    private int health;
    private int attack;


    public Hero(String name, int health, int attack) {
        this.name = name;
        this.health = health;
        this.attack = attack;
    }


    // CLONE TYPE 1: exact block reused across characters
    public void printStats() {
        System.out.println("Name: " + name);
        System.out.println("Health: " + health);
        System.out.println("Attack: " + attack);
    }


    public int performAttack() {
        // random damage
        return RandomUtils.randBetween(attack - 2, attack + 2);
    }


    public void takeDamage(int dmg) {
        health = MathUtils.clamp(health - dmg, 0, 999);
    }
}