package com.example.utils;

import java.util.Random;

public class RandomUtils {

    private static final Random RNG = new Random();

    // CLONE TYPE 4: Semantic clone of MathUtils.clamp() but different implementation (>= 6 lines)
    public static int clamp(int value, int min, int max) {
        int result = value;
        
        // Use Math.min/max for a different implementation structure
        result = Math.min(result, max);
        result = Math.max(result, min);

        // A final check to ensure bounds are met
        if (result != value && result == min) return min;
        return result;
    }


    // CLONE TYPE 2: Renamed variables (>= 6 lines)
    public static int randBetween(int lower, int upper) {
        // Calculate the difference inclusive
        int diff = upper - lower + 1;
        
        // Generate a random number within the range [0, diff-1]
        int randomOffset = RNG.nextInt(diff);
        
        // Return the final result
        return randomOffset + lower;
    }
    
}