package com.example.ui;

public class ConsoleRenderer {

    // Possibly Type 2, but between 2 methods total (whole file)
    public void printHeader(String text) {
        System.out.println("====================");
        System.out.println(text);
        System.out.println("====================");
    }

    public void printLine(String text) {
        System.out.println("-> " + text);
    }
}