package com.example.ui;


public class MenuPrinter {


    // CLONE TYPE 3: similar to ConsoleRenderer.printHeader but extra space
    public void showTitle(String text) {
        System.out.println("********************");
        System.out.println(" " + text);
        System.out.println("********************");
    }


    // CLONE TYPE 3: slightly different formatting
    public void showOption(String text) {
        System.out.println("[ ] " + text);
    }
}