
**Installation**

* Run the following commands to install the .exe file
    1. 
    ```
        bison –y project.y -d
    ```
    2. 
    ```
        flex project.l
    ```
    3. 
    ```
        gcc y.tab.c lex.yy.c
    ```

* Run the following command to run the .exe program taking inputs from the command line
    ```
        a.exe
    ```

* Run the following command to run the .exe program taking inputs from file
    ```
        a.exe <inputfile.txt> outputfile.txt
    ```

* Available test case files
    1- testcase1.txt: provides operations in integers and floats such as =,+, -,* and / and unary - and in different variations  eg x=3+2;  x+=2;
                        to run this test case use the following command ``` a.exe <testcase1.txt> output1.txt ```

    2- testcase2.txt: provides operations in string and characters such as =,+(for string concatnation)and in different variations  eg x="emad";  t='c';
                        to run this test case use the following command ``` a.exe <testcase2.txt> output2.txt ```

    3- testcase3.txt: provides error "used without type definintion" 
                        to run this test case use the following command ``` a.exe <testcase3.txt> output3.txt ```

    4- testcase4.txt: provides error "used without being initialised" 
                        to run this test case use the following command ``` a.exe <testcase4.txt> output4.txt ```

    5- testcase5.txt: provides error "type mismatch" 
                        to run this test case use the following command ``` a.exe <testcase5.txt> output5.txt ```

    6- testcase6.txt: provides error "variable redeclaration"
                        to run this test case use the following command ``` a.exe <testcase6.txt> output6.txt ```

    7- testcase7.txt: provides error "This operator cannot be applied to strings"
                        to run this test case use the following command ``` a.exe <testcase7.txt> output7.txt ```

    NOTE THAT: each error lead to the system to exit, so we have to make a test case for each error sepratly


**Usage**

1. Vairable declaration
    I.   Declaring an integer 'x' with/without initial value
                            ```
                                int x;
                                int x = 2;
                            ```

    II.  Declaring a string 'x' with/without initial value
                            ```
                                string x;
                                string x = "Lex";
                            ```

    III. Declaring a float 'x' with/without initial value
                            ```
                                float x;
                                float x = 2.3;
                            ```

    IV.  Declaring a character 'x' with/without initial value
                            ```
                                char x;
                                char x = 'L';
                            ```


2. Operations
    I. Standard operations
    - Add '+' (int, float, string, char)
    ```
        x = 3 + 2;
    ```
    - Subtract '-' (int, float, char)
    ```    
        x = 3 - 2;
    ```
    - Multiply '*' (int, float, char) *Bonus Addition*
    ```    
        x = 3 * 2;
    ```
    - Divide '/' (int, float, char) *Bonus Addition*
    ```
        x = 3 / 2;
    ```
    
    II. Unary Operations *Bonus Addition*
        - Subtraction (int, float)
        ```    
            x = -1;
        ```

    III. Atomic Operations *Bonus Addition*
    - To add a certain value to a variable, you can do it like
    ```
        x = x + z;
    ```
    to add z to the current value of x
    - Alternatively, you could also do
    ```
        x += z;
    ```
    which would do the same operation as above
    
    - Add
    ```
        x += 2;
    ```
    - Subtract
    ```
        x -= 2;
    ```
    - Multiply
    ```
        x *= 2;
    ```
    - Divide
    ```
        x /= 2;
    ```

    IV. Print *Bonus addition for debug*
    - Applies to all data types
    ```
        int x = 2;
        print(x);
        float y = 3.5;
        print(y);
        char c = 's';
        print(c);
        string z = "Lex";
        print(z);
    ```


3. Errors
    I. Variable redeclaration *Bonus Addition*
    ```
        int x = 2;
        int x = 4;
    ```
    
    II. Use of undeclared variable *Bonus Addition*
    ```
        int x = 4;
        int y = z + x;
    ```
    (where z is an undeclared variable)

    III. Use of uninitialized variable
    ```    
        int x;
        int y = x + 2;
    ```
    
    IV. Type mismatch
    ```
        int x = 3;
        float y = 5.4 + x;
    ```

    V.  Incompatible operations *Bonus Addition*
    ```
        string x = -"Lex";
        string y = "Yacc" - "Lex";
    ```


4. Comments *Bonus Addition*
    - Add '//' before any line to be considered a comment
    ```
        // This line adds two integers
    ```

