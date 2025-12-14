package com.example.items;

import com.example.characters.Hero;
import com.example.characters.Mage;

public interface Usable {
    boolean use(Hero hero);
    boolean use(Mage mage);
}