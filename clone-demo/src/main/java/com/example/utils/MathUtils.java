package com.example.utils;


import java.util.Random;


public class MathUtils {


private static final Random RAND = new Random();


    // CLONE TYPE 4: Semantic clone of RandomUtils.clamp() but different implementation (>= 6 lines)
    public static int clamp(int value, int min, int max) {
        if (value < min) {
            // If below min, return min
            return min;
        }
        if (value > max) {
            // If above max, return max
            return max;
        }
        // If within bounds, return original value
        return value;
    }


    // CLONE TYPE 2: Renamed identifiers copy of RandomUtils.randBetween (>= 6 lines)
    public static int randomRange(int min, int max) {
        // Calculate the range inclusive
        int range = max - min + 1;
        
        // Get a random offset from 0 up to range - 1
        int randVal = RAND.nextInt(range);
        
        // Add the minimum value to get the final result
        return randVal + min;
    }
}