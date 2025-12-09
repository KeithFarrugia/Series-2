package com.example;


import com.example.characters.Hero;
import com.example.characters.Mage;
import com.example.enemies.Goblin;
import com.example.enemies.Orc;
import com.example.items.Potion;
import com.example.combat.BattleSimulator;
import com.example.ui.ConsoleRenderer;
import com.example.ui.MenuPrinter;
import com.example.ui.GameWindow; 
import com.example.ui.BattlePanel;

public class Main {
    public static void main(String[] args) {
        
        // 1. INITIALIZE UI COMPONENTS
        ConsoleRenderer renderer = new ConsoleRenderer();
        MenuPrinter menu = new MenuPrinter();
        
        BattlePanel battlePanel = new BattlePanel();
        GameWindow gameWindow = new GameWindow(battlePanel);
        
        renderer.printHeader("CLONE DETECTOR RPG BENCHMARK");
        menu.showTitle("Welcome to the Graphical Demo");

        // 2. Initialization (Characters and Enemies)
        Hero hero = new Hero("Jacob", 50, 10, 5);
        Mage mage = new Mage("Keith", 40, 12, 3);
        Goblin goblin = new Goblin();
        Orc orc = new Orc();
        
        // 3. Combat Simulation - Pass the UI components
        BattleSimulator simulator = new BattleSimulator(renderer, gameWindow, battlePanel);
        simulator.startBattle(hero, mage, goblin, orc);


        // 5. Final Status
        renderer.printHeader("POST-BATTLE STATUS");
        hero.printStats();
        mage.showStats();
    }
}