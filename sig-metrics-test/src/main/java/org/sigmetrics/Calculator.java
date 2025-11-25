package org.sigmetrics;
// A simple calculator class with basic arithmetic operations
public class Calculator {

    /**
     * Adds two integers.
     * @param a the first integer
     * @param b the second integer
     * @return the sum of a and b
     */
    public int add(int a, int b) {
        int sum = a + b;
        System.out.println("Adding " + a + " and " + b + ": " + sum);
        return sum;
    }

    /**
     * Subtracts the second integer from the first.
     * @param a the first integer
     * @param b the second integer
     * @return the difference of a and b
     */
    public int subtract(int a, int b) {
        int difference = a - b;
        System.out.println("Subtracting " + b + " from " + a + ": " + difference);
        return difference; // Returns the difference of a and b
    }

    /**
     * Multiplies two integers.
     * @param a the first integer
     * @param b the second integer
     * @return the product of a and b
     */
    public int multiply(int a, int b) {
        int product = a * b;
        System.out.println("Multiplying " + a + " by " + b + ": " + product);
        return product;
    }

    /**
     * Divides the first integer by the second.
     * @param a the numerator
     * @param b the denominator
     * @return the quotient of a divided by b
     * @throws IllegalArgumentException if b is zero
     */
    public int divide(int a, int b) {
        if (b == 0) {
            System.out.println("Division error: division by zero.");
            throw new IllegalArgumentException("Cannot divide by zero");
        }
        int quotient = a / b;
        System.out.println("Dividing " + a + " by " + b + ": " + quotient);
        return quotient;
    }


    /**     * Raises a number to a power.
     * @param base the base number
     * @param exponent the exponent
     * @return the result of base raised to the power of exponent
     */
    public double power(double base, double exponent) {
        double result = Math.pow(base, exponent);
        System.out.println("Computing " + base + " raised to " + exponent + ": " + result);
        return result;
    }

    /**
     * Computes the square root of a value.
     * @param value the value to compute the square root of
     * @return the square root of the value
     * @throws IllegalArgumentException if the value is negative
     */
    public double root(double value) {
        if (value < 0) {
            System.out.println("Square root error: negative input.");
            throw new IllegalArgumentException("Cannot compute root of negative value");
        }
        double result = Math.sqrt(value);
        System.out.println("Computing square root of " + value + ": " + result);
        return result;
    }

    /** Computes the modulo of two integers.
     * @param a the first integer
     * @param b the second integer
     * @return the remainder of a divided by b
     * @throws IllegalArgumentException if b is zero
     */
    public int modulo(int a, int b) {
        if (b == 0) {
            System.out.println("Modulo error: division by zero.");
            throw new IllegalArgumentException("Cannot take modulo by zero");
        }
        int result = a % b;
        System.out.println("Calculating " + a + " % " + b + ": " + result);
        return result;
    }

    /**
     * Computes the absolute value of an integer.
     * @param value the integer value
     * @return the absolute value of the input
     */
    public int absolute(int value) {
        int result = Math.abs(value);
        System.out.println("Absolute value of " + value + ": " + result);
        return result;
    }

    /**
     * Computes the minimum of two integers.
     * @param a the first integer
     * @param b the second integer
     * @return the minimum of a and b
     */
    public int min(int a, int b) {
        int result = Math.min(a, b);
        System.out.println("Minimum of " + a + " and " + b + ": " + result);
        return result;
    }

    /**
     * Computes the maximum of two integers.
     * @param a the first integer
     * @param b the second integer
     * @return the maximum of a and b
     */
    public int max(int a, int b) {
        int result = Math.max(a, b);
        System.out.println("Maximum of " + a + " and " + b + ": " + result);
        return result;
    }
}
// End of Calculator.java