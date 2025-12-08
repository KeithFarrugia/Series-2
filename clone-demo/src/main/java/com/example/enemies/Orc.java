package com.example.enemies;


import com.example.utils.RandomUtils;


public class Orc {
    private int life;
    private int power;


    public Orc() {
        this.life = 35;
        this.power = 7;
    }


    // CLONE TYPE 3: similar to Goblin.printStats but extra line and diff names
    public void printStats() {
        System.out.println("Enemy: Orc");
        System.out.println("HP: " + life);
        System.out.println("ATK: " + power);
        System.out.println("The orc growls...");
    }


    public int smash() {
        // CLONE TYPE 4: semantically same as Goblin.dealDamage but different structure
        int min = power - 2;
        int max = power + 2;
        return RandomUtils.randBetween(min, max);
    }


    public void suffer(int dmg) {
        life -= dmg;
        if (life < 0) life = 0;
    }
}