package com.example.ui;
public class MenuPrinter {

    // Type 2 with Console Render
    public void showTitle(String text) {
        System.out.println("********************");
        System.out.println(text);
        System.out.println("********************");
    }

    public void showOption(String text) {
        System.out.println("-> " + text);
    }
}