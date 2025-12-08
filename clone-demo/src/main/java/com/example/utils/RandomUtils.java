package com.example.utils;

import java.util.Random;

public class RandomUtils {

    private static final Random RNG = new Random();

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


    // CLONE TYPE 2: renamed version of randomRange
    public static int randBetween(int lower, int upper) {
        int diff = upper - lower + 1;
        return RNG.nextInt(diff) + lower;
    }
    
}