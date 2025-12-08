package com.example.ui;


public class ConsoleRenderer {


    // CLONE TYPE 3: similar to MenuPrinter but with slight differences
    public void printHeader(String text) {
        System.out.println("====================");
        System.out.println(text);
        System.out.println("====================");
    }


    // CLONE TYPE 3: minor difference
    public void printLine(String text) {
        System.out.println("-> " + text);
    }
}