package java_programs.conditions;

import java.util.*;

public class GreatestOf3_Simple1 {
    public static void main(String[] args) {
        Scanner sc=new Scanner(System.in);
        System.out.print("Enter 3 numbers : ");
        int a=sc.nextInt(),b=sc.nextInt(),c=sc.nextInt();
        if(a>b && a>c)
            System.out.print("Greatest no. : "+a);
        else if(b>c)
            System.out.print("Greatest no. : "+b);
        else
            System.out.print("Greatest no. : "+c);
            sc.close();
    }
}