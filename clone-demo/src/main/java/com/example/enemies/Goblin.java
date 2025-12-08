package com.example.enemies;

import com.example.utils.RandomUtils;


public class Goblin {
    private int hp;
    private int attack;


    public Goblin() {
        this.hp = 20;
        this.attack = 5;
    }


    // CLONE TYPE 1: exact across enemies
    public void printStats() {
        System.out.println("Enemy: Goblin");
        System.out.println("HP: " + hp);
        System.out.println("ATK: " + attack);
    }


    public int dealDamage() {
        return RandomUtils.randBetween(attack - 1, attack + 1);
    }


    public void hit(int dmg) {
        hp -= dmg;
        if (hp < 0) hp = 0;
    }
}
