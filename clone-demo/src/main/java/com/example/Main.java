package com.example;


import com.example.characters.Hero;
import com.example.characters.Mage;
import com.example.enemies.Goblin;
import com.example.enemies.Orc;
import com.example.ui.ConsoleRenderer;
import com.example.ui.MenuPrinter;


public class Main {
    public static void main(String[] args) {
        ConsoleRenderer renderer = new ConsoleRenderer();
        MenuPrinter menu = new MenuPrinter();


        renderer.printHeader("Clone Demo RPG");
        menu.showTitle("Welcome Player");


        Hero hero = new Hero("Arin", 50, 10);
        Mage mage = new Mage("Zaros", 40, 12);


        Goblin goblin = new Goblin();
        Orc orc = new Orc();


        hero.printStats();
        mage.showStats();


        goblin.printStats();
        orc.printStats();


        System.out.println("Battle simulation starting...");


        int heroHit = hero.performAttack();
        int mageHit = mage.cast();
        int goblinHit = goblin.dealDamage();
        int orcHit = orc.smash();


        System.out.println("Hero deals: " + heroHit);
        System.out.println("Mage deals: " + mageHit);
        System.out.println("Goblin deals: " + goblinHit);
        System.out.println("Orc deals: " + orcHit);


        System.out.println("Demo complete. Clones displayed across classes.");
    }
}