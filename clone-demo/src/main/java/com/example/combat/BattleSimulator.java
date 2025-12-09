package com.example.combat;

import com.example.characters.Hero;
import com.example.characters.Mage;
import com.example.enemies.Goblin;
import com.example.enemies.Orc;
import com.example.ui.ConsoleRenderer;
import com.example.ui.GameWindow; 
import com.example.ui.BattlePanel;

import java.util.Random;

public class BattleSimulator {

    private ConsoleRenderer renderer;
    private static final Random RNG = new Random();
    private GameWindow gameWindow;
    private BattlePanel battlePanel;

    public BattleSimulator(ConsoleRenderer renderer, GameWindow window, BattlePanel panel) {
        this.renderer = renderer;
        this.gameWindow = window;
        this.battlePanel = panel;
    }

    // CLONE TYPE 2 with calculateGoldReward
    private int calculateXpReward(int enemyLevel) {
        // Base XP is proportional to enemy level
        int baseXP = enemyLevel * 15; 
        
        // Add random variance to make rewards unpredictable
        int variance = RNG.nextInt(11) - 5; // Range [-5, 5]
        int finalXP = baseXP + variance;

        // Ensure XP is never negative
        return Math.max(1, finalXP);
    }

    private int calculateGoldReward(int enemyLevel) {
        // Base Gold is proportional to enemy level
        int baseGold = enemyLevel * 5;
        
        // Add random variance to make rewards unpredictable
        int variance = RNG.nextInt(5) - 2; // Range [-2, 2]
        int finalGold = baseGold + variance;

        // Ensure gold is never negative
        return Math.max(0, finalGold);
    }

    public void startBattle(Hero hero, Mage mage, Goblin goblin, Orc orc) {
        renderer.printHeader("BATTLE COMMENCES!");
        
        int round = 1;

        // Simulation Loop
        while (hero.getHealth() > 0 && mage.getHp() > 0 && (goblin.getHp() > 0 || orc.getLife() > 0)) {
            renderer.printLine("\n--- Round " + round + " ---\n");

            // 1. HERO ATTACKS (Action Display Logic Added)
            if (goblin.getHp() > 0) {
                int damage = hero.slash();
                renderer.printLine("-> " + hero.getName() + " attacks Goblin for " + damage + " damage.");
                gameWindow.displayAction(hero.getName(), "Goblin", "Slash"); // Call the UI
                battlePanel.waitForAnimation(); // PAUSE
                goblin.hit(damage);
            } else if (orc.getLife() > 0) {
                int damage = hero.slash();
                renderer.printLine("-> " + hero.getName() + " attacks Orc for " + damage + " damage.");
                gameWindow.displayAction(hero.getName(), "Orc", "Slash"); // Call the UI
                battlePanel.waitForAnimation(); 
                orc.suffer(damage);
            }
            
            // 2. MAGE ATTACKS (Action Display Logic Added)
            if (orc.getLife() > 0) {
                int damage = mage.cast();
                renderer.printLine("-> " + mage.getAlias() + " casts on Orc for " + damage + " magic damage.");
                gameWindow.displayAction(mage.getAlias(), "Orc", "Cast"); // Call the UI
                battlePanel.waitForAnimation(); 
                orc.suffer(damage);
            }
            
            hero.printHealth();
            mage.printHP();
            goblin.printHP();
            orc.printLife();

            round++;
            if (round > 10) break; // Safety break
        }

        // 4. POST-BATTLE LOGIC (CLONE TARGET)
        if (hero.getHealth() > 0 || mage.getHp() > 0) {
            renderer.printHeader("VICTORY!");
            
            int totalXP = 0;
            int totalGold = 0;
            
            // This entire reward section provides an excellent block for Type 1, 2, and 3 clones in future expansions.
            if (goblin.getHp() <= 0) {
                int xp = calculateXpReward(1);
                int gold = calculateGoldReward(1);
                renderer.printLine("Goblin defeated! Hero gains " + xp + " XP and " + gold + " Gold.");
                totalXP += xp;
                totalGold += gold;
            }
            
            if (orc.getLife() <= 0) {
                int xp = calculateXpReward(3);
                int gold = calculateGoldReward(3);
                renderer.printLine("Orc defeated! Mage gains " + xp + " XP and " + gold + " Gold.");
                totalXP += xp;
                totalGold += gold;
            }
            
            // Apply rewards and check for level up
            hero.addXp(totalXP);
            mage.addXp(totalXP);
            
            hero.addGold(totalGold);
            mage.addGold(totalGold);
            
        } else {
            renderer.printHeader("DEFEAT...");
            renderer.printLine("All heroes have fallen.");
        }
    }
}