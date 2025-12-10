package com.example.enemies;

import com.example.utils.RandomUtils;


public class Goblin {
    private int hp;
    private int attack;
    private int evasion;


    public Goblin() {
        this.hp = 20;
        this.attack = 5;
        this.evasion = 10;
    }

    public void printStats() {
        System.out.println("===============================");
        System.out.println("ENEMY STATS: Goblin");
        System.out.println("-------------------------------");
        System.out.println("Health: " + hp + " HP");
        System.out.println("Attack Power: " + attack + " ATK");
        System.out.println("Evasion Rate: " + evasion + " %");
        System.out.println("===============================");
    }


    public int dealDamage() {
        return RandomUtils.randBetween(attack - 1, attack + 1);
    }


    public void hit(int dmg) {
        // Small chance to evade the hit
        if (RandomUtils.randBetween(1, 100) < evasion) {
            System.out.println("Goblin dodged the attack!");
            return;
        }

        hp -= dmg;
        if (hp < 0) hp = 0;
    }

    public int getHp() {
        return hp;
    }

    public void printHP() {
        System.out.println("Goblin HP: " + hp);
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