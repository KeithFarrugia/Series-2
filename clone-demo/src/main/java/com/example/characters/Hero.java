package com.example.characters;


import com.example.utils.MathUtils;
import com.example.utils.RandomUtils;


public class Hero {
    private String name;
    public int health;
    private int attack;
    private int armor;
    private int level;
    private int experience;
    private int xp;
    private int gold;

    public Hero(String name, int health, int attack, int armor) {
        this.name = name;
        this.health = health;
        this.attack = attack;
        this.armor = armor;
        this.level = 1;
        this.experience = 0;
        this.gold = 0;
    }

    // CLONE TYPE 2: renamed variables
    public void printStats() {
        System.out.println("===============================");
        System.out.println("HERO STATS: " + name + " (Lvl " + level + ")"); 
        System.out.println("-------------------------------");
        System.out.println("Health: " + health + " HP");
        System.out.println("Attack Power: " + attack + " ATK");
        System.out.println("Armor Rating: " + armor + " DEF");
        System.out.println("Current Gold: " + gold + " G"); 
        System.out.println("Experience: " + experience + "/" + calculateXpToNextLevel()); 
        System.out.println("===============================");
    }

    // CLONE TYPE 4: Semantic clone of Mage.cast() but implemented differently (>= 6 lines)
    public int slash() {
        // Calculate a random damage value
        int minDamage = attack - 2;
        int maxDamage = attack + 2;
        int damage = RandomUtils.randBetween(minDamage, maxDamage);
        
        // Add a small bonus based on armor
        damage += (armor / 5);

        return damage;
    }

    public void takeDamage(int dmg) {
        // Simple damage reduction by armor
        int effectiveDamage = Math.max(1, dmg - (armor / 2));
        health = MathUtils.clamp(health - effectiveDamage, 0, 999);
    }

    public void addXp(int xp) {
        this.experience += xp;
        System.out.println(name + " gained " + xp + " experience!");
        
        while (this.experience >= calculateXpToNextLevel()) {
            levelUp();
        }
    }
    
    private int calculateXpToNextLevel() {
        // Simple scaling formula: 100 * Level
        return 100 * level; 
    }
    
    // Type 2 clone with Mage
    private void levelUp() {
        this.experience -= calculateXpToNextLevel();
        this.level++;
        this.health += 5; // Base stat growth
        this.attack += 2;
        this.armor += 1;
        System.out.println("🌟 " + name + " leveled up to Level " + level + "! 🌟");
    }
    
    public void addGold(int amount) {
        this.gold += amount;
    }

    public int getHealth() {
        return health;
    }

    public void setHealth(int health) {
        this.health = health;
    }

    public String getName() {
        return name;
    }

    public void printHealth() {
        System.out.println(name + " has " + health + " HP remaining.");
    }

    public int getXp() {
        return xp;
    }

    public int getLevel() {
        return level;
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