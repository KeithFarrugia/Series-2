package org.sigmetrics;
public class Duplication {
    void adding(){
        int a = 1;   // line 0
        int b = 2;   // line 1
        int c = 3;   // line 2
        int d = 4;   // line 3
        int e = 5;   // line 4
        int f = 6;   // line 5
        int g = 7;   // line 6
        for(
            int i=0; 
            i<10; 
            i++
        ){
            System.out.println(i);
        }
        switch (a) {
            case 1:
                System.out.println("One");
                break;
            case 2:
                System.out.println("Two");
                break;
            default:
                break;
        }
        if (a == 0) {
            System.out.println("Zero");
        }else {
            System.out.println("Not Zero");
        }
    }
    void adding2(){
        int a = 1;   // line 7
        int b = 2;   // line 8
        int c = 3;   // line 9
        int d = 4;   // line 10
        int e = 5;   // line 11
        int f = 6;   // line 12
        int g = 7;   // line 13
        int asda = 1;   // line 7
    }
}