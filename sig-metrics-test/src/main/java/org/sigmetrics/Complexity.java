package org.sigmetrics;

/**
 * Class used to test cyclomatic complexity calculations.
 */
public class Complexity {

    public int simpleIf(int x) {
        if (x > 0)
            return 1;
        return 0;
    }
    
    public int nestedIfElse(int x, int y) {
        if (x > 0) {
            if (y > 0)
                return 1;
            else
                return 2;
        } else {
            return 3;
        }
    }

    public int loopExample(int n) {
        int total = 0;
        for (int i = 0; i < n; i++) {
            if (i % 2 == 0)
                total += i;
        }
        return total;
    }

    public int switchExample(int x) {
        switch (x) {
            case 0: return 0;
            case 1: return 1;
            default: return -1;
        }
    }

    public int tryCatchExample(int x, int y) {
        try {
            return x / y;
        } catch (ArithmeticException e) {
            return -1;
        }
    }

    public int complexConditions(int a, int b) {
        // logical operators and ternary condition
        return (a > 0) ? 1 : 2;
    }
}