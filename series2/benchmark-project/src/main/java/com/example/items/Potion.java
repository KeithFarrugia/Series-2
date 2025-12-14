package com.example.items;

import com.example.characters.Hero;
import com.example.characters.Mage;
import com.example.utils.MathUtils;

public class Potion implements Usable {
    private String name;
    private int restoreAmount;

    public Potion(String name, int restoreAmount) {
        this.name = name;
        this.restoreAmount = restoreAmount;
    }
    
    // CLONE TYPE 3: Similar to other usage methods, but logic differs slightly (>= 6 lines)
    @Override
    public boolean use(Hero hero) {
        int currentHealth = hero.getHealth();
        int maxHealth = 50 + hero.getLevel() * 5; 
        
        // Calculate the actual health restored
        int restored = MathUtils.clamp(currentHealth + restoreAmount, 0, maxHealth) - currentHealth;
        
        if (restored > 0) {
            hero.setHealth(currentHealth + restored);
            System.out.println(hero.getName() + " uses " + name + " and restores " + restored + " HP.");
            return true;
        } else {
            System.out.println(hero.getName() + " is already at full health!");
            return false;
        }
    }

    @Override
    public boolean use(Mage mage) {
        // Mage can't use HP Potion
        System.out.println(mage.getAlias() + " can only use mana items.");
        return false;
    }

    public String getName() {
        return name;
    }
}