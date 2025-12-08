package com.example.characters;

import com.example.utils.MathUtils;
import com.example.utils.RandomUtils;

public class Mage {
    private String alias;
    private int hp;
    private int magicPower;


    public Mage(String alias, int hp, int magicPower) {
        this.alias = alias;
        this.hp = hp;
        this.magicPower = magicPower;
    }


    // CLONE TYPE 2: same method as Hero.printStats but renamed variables
    public void showStats() {
        System.out.println("Name: " + alias);
        System.out.println("Health: " + hp);
        System.out.println("Attack: " + magicPower);
    }


    public int cast() {
        return RandomUtils.randBetween(magicPower - 3, magicPower + 3);
    }


    public void receiveDamage(int dmg) {
        hp = MathUtils.clamp(hp - dmg, 0, 999);
    }
}
