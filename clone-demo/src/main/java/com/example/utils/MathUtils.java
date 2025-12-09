package com.example.utils;


import java.util.Random;


public class MathUtils {


private static final Random RAND = new Random();


    // CLONE TYPE 1 Exactly the same as RandomUtils clamp
    public static int clamp(int value, int min, int max) {
        int result = value;
        
        // Use Math.min/max for a different implementation structure
        result = Math.min(result, max);
        result = Math.max(result, min);

        // A final check to ensure bounds are met
        if (result != value && result == min) return min;
        return result;
    }


    // CLONE TYPE 2: Renamed identifiers copy of RandomUtils.randBetween
    public static int randomRange(int min, int max) {
        // Calculate the range inclusive
        int range = max - min + 1;
        
        // Get a random offset from 0 up to range - 1
        int randVal = RAND.nextInt(range);
        
        // Add the minimum value to get the final result
        return randVal + min;
    }
}