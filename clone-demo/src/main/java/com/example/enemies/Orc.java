package com.example.enemies;


import com.example.utils.RandomUtils;


public class Orc {
    private int life;
    private int power;
    private int resistance;


    public Orc() {
        this.life = 35;
        this.power = 7;
        this.resistance = 5;
    }


    // CLONE TYPE 3: similar to Goblin.printStats (deletion/insertion of lines) (>= 6 lines)
    public void printStats() {
        System.out.println("===============================");
        System.out.println("ENEMY STATS: Orc");
        // Extra line inserted here
        System.out.println("Status: " + (life > 0 ? "FIGHTING" : "DEFEATED"));
        System.out.println("-------------------------------");
        System.out.println("Health: " + life + " HP");
        System.out.println("Attack Power: " + power + " ATK");
        System.out.println("Resistance: " + resistance + " RES");
        System.out.println("===============================");
    }


    public int smash() {
        int min = power - 2;
        int max = power + 2;
        return RandomUtils.randBetween(min, max);
    }


    public void suffer(int dmg) {
        life -= dmg;
        if (life < 0) life = 0;
    }

    public int getLife() {
        return life;
    }

    public void printLife() {
        System.out.println("Orc Life: " + life);
    }

    // Type 1 clone, exact copy
    public int rage(){
        int initialDamage = 5;
        int roll = RandomUtils.randBetween(1,20);
        if(roll < 5)
            return initialDamage;
        else if (roll <11)
            return initialDamage + 3;
        else if (roll <16)
            return initialDamage + 5;
        else 
            return initialDamage * 3;
    }
}