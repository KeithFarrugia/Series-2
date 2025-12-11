package com.example.characters;

import com.example.utils.MathUtils;
import com.example.utils.RandomUtils;

public class Mage {
    private String alias;
    public int hp;
    private int magicPower;
    private int resistance;
    private int level;
    private int experience;
    private int gold;

    public Mage(String alias, int hp, int magicPower, int resistance) {
        this.alias = alias;
        this.hp = hp;
        this.magicPower = magicPower;
        this.resistance = resistance;
        this.level = 1;
        this.experience = 0;
        this.gold = 0;
    }

    // CLONE TYPE 2: same method as Hero.printStats but renamed variables (>= 6 lines)
    public void showStats() {
        System.out.println("*******************************");
        System.out.println("MAGE STATS: " + alias + " (Lvl " + level + ")"); 
        System.out.println("-------------------------------");
        System.out.println("Health: " + hp + " HP");
        System.out.println("Magic Power: " + magicPower + " MAG");
        System.out.println("Magic Resist: " + resistance + " RES");
        System.out.println("Current Gold: " + gold + " G"); 
        System.out.println("Experience: " + experience + "/" + calculateXpToNextLevel()); 
        System.out.println("*******************************");
    }


    // CLONE TYPE 4: Semantic clone of Hero.performAttack() but implemented differently (>= 6 lines)
    public int cast() {
        // Calculate a random magic damage
        int baseDamage = magicPower;
        int variance = RandomUtils.randBetween(-3, 3);
        int damage = baseDamage + variance;

        // Apply a multiplier for critical hit chance
        if (RandomUtils.randBetween(1, 100) > 85) {
            damage *= 2; // 15% chance for double damage
        }
        
        return damage;
    }


    public void receiveDamage(int dmg) {
        // Simple damage reduction by resistance
        int effectiveDamage = Math.max(1, dmg - (resistance / 3));
        hp = MathUtils.clamp(hp - effectiveDamage, 0, 999);
    }

    public void addXp(int xp) {
        this.experience += xp;
        System.out.println(alias + " gained " + xp + " experience!");
        
        while (this.experience >= calculateXpToNextLevel()) {
            levelUp();
        }
    }

    public void printHealth() {
        System.out.println("[MAGE] " + alias + " HP: " + hp);
    }

    public int getHp() {
        return hp;
    }


    public String getAlias() {
        return alias;
    }

    public void printHP() {
        System.out.println(alias + " HP: " + hp);
    }   

    private int calculateXpToNextLevel() {
        // Simple scaling formula: 100 * Level * 1.5
        return (int)(150 * level); 
    }
    
    // Type 2 clone
    private void levelUp() {
        this.experience -= calculateXpToNextLevel();
        this.level++;
        this.hp += 3; // Base stat growth
        this.magicPower += 3;
        this.resistance += 1;
        System.out.println("✨ " + alias + " leveled up to Level " + level + "! ✨");
    }
    
    public void addGold(int amount) {
        this.gold += amount;
    }

    // Type 1, exact clone copied and pasted
    public static String getStatusColor(String status) {
        if ("FIGHTING".equals(status)) {
            return "GREEN";
        } else if ("DEFEATED".equals(status)) {
            return "RED";
        } else {
            return "WHITE";
        }
    }
}