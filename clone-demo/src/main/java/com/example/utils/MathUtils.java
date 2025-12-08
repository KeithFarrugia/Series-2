package com.example.utils;


import java.util.Random;


public class MathUtils {


private static final Random RAND = new Random();


    // CLONE TYPE 1: exact copy appears in RandomUtils
    public static int clamp(int value, int min, int max) {
        if (value < min) {
            return min;
        }
        if (value > max) {
            return max;
        }
        return value;
    }


    // CLONE TYPE 2: renamed identifiers copy in RandomUtils
    public static int randomRange(int min, int max) {
        int range = max - min + 1;
        return RAND.nextInt(range) + min;
    }
}