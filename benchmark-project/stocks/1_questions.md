# Question 1

Suppose you are developing a similar (if not identical) project for a company. One teammate poses the following:

> "We do not have to worry about logging. The application is very small and tests should take care of any potential bugs. If we really need it, we can print some important data and just comment it out later."

Do you agree or disagree with the proposition? Please elaborate on your reason to agree or disagree. (~50-100 words)

___

**Answer**:

We disagree with this statement as tests are useful for identifying bugs but may not catch all bugs or errors, thus logs serve as a real-time, persistent source of information about the application's behavior. They provide insights into how the application runs in production, help in diagnosing issues, and can be invaluable for debugging unexpected scenarios. Also, removing log statements later can be very tedious and inaccurate to as what should be logged and how.

# Question 2

Suppose you have the following `LinkedList` implementation:

![LinkedList](images/LinkedList.png)

How could you modify the `LinkedList` class so that the value could be any different data type? Preferably, provide the code of the modified class in the answer.
___

**Answer**:

public class Node<T> {
    private T value;
    private Node<T> next;
    public Node(T value) {
        this.value = value;
        this.next = null;
    }

    public T getValue() {
        return value;
    }

    public Node<T> getNext() {
        return next;
    }

    public void setNext(Node<T> next) {
        this.next = next;
    }

    public void setValue(T value) {
        this.value = value;
    }
}

public class LinkedList<T> {
    private Node<T> head;
    private int size;
    LinkedList() {
        this.head = null;
        this.size = 0;
    }

    public void insert(T value) {
        Node<T> node = new Node<>(value);
        if (head == null) {
            size = 1;
            head = node;
            return;
        }

        Node<T> current = head;
        while (current.getNext() != null) {
            current = current.getNext();
        }
        current.setNext(node);
        size++;
    }

    public void delete(T value) {
        if (head == null) {
            return;
        }

        if (head.getValue() == value) {
            head = head.getNext();
            size--;
            return;
        }

        Node<T> current = head;
        Node<T> previous = null;

        while (current != null && current.getValue() != (value)) {
            previous = current;
            current = current.getNext();
        }

        if (current != null) {
            previous.setNext(current.getNext());
            size--;
        }
    }


    public void printList() {
        Node<T> current = head;
        while (current != null) {
            System.out.println(current.getValue());
            current = current.getNext();
        }
    }
}

___

# Question 3

How is Continuous Integration applied to (or enforced on) your assignment? (~30-100 words)
 
___

**Answer**:

Continuous Integration (CI) plays a pivotal role in our assignment workflow. By using  Git and GitHub as our foundation for version control and collaboration. Initially, we maintain separate branches - 'duq' and 'JacobPersonal,' allowing us to work on our respective versions independently. We frequently scheduled to discuss and resolve any conflicts that arise. Once we are happy with the overall implementation we merge our work into a shared branch, 'duq,' which is then tweaked and improved until we have a  final version. 

___

# Question 4

One of your colleagues wrote the following class:

```java
import java.util.*;

public class MyMenu {

    private Map<Integer, PlayerAction> actions;

    public MyMenu() {
        actions = new HashMap<>();
        actions.put(0, DoNothingAction());
        actions.put(1, LookAroundAction());
        actions.put(2, FightAction());
    }

    public void printMenuOptions(boolean isInCombat) {
        List<String> menuOptions = new ArrayList<>();
        menuOptions.add("What do you want to?");
        menuOptions.add("\t0) Do nothing");
        menuOptions.add("\t1) Look around");
        if(isInCombat) {
            menuOptions.add("\t2) Fight!");
        }
        menuOptions.forEach(System.out::println);
    }

    public void doOption() {
        int option = getNumber();
        if(actions.containsKey(option)) {
            actions.get(option).execute();
        }
    }

    public int getNumber() {
        Scanner scanner = new Scanner(System.in);
        return scanner.nextInt();
    }
}
```
List at least 2 things that you would improve, how it relates to test-driven development and why you would improve these things. Provide the improved code below.

___

**Answer**:

1: Error handling for user input:
In the current implementation, if the user inputs something that is not an integer between 0 and 2 an exception will be thrown. The getNumber() method can be modified to deal with this in the code below

2: Actions Encapsulated within method:
In the current implementation, the actions are stored in a Map<Integer, PlayerAction>, but actions aren't defined anywhere and thus the aaction implementation can be improved by encapsulating the actions within classes. This way, you can easily add new actions in the future without modifying the MyMenu class and can test the action functions individually.
-
Improved code:

import java.util.*;

public class MyMenu {

    private Map<Integer, PlayerAction> actions;

    public MyMenu() {
        actions = new HashMap<>();
        actions.put(0, new DoNothingAction());
        actions.put(1, new LookAroundAction());
        actions.put(2, new FightAction());
    }

    public void printMenuOptions(boolean isInCombat) {
        List<String> menuOptions = new ArrayList<>();
        menuOptions.add("What do you want to?");
        menuOptions.add("\t0) Do nothing");
        menuOptions.add("\t1) Look around");
        if (isInCombat) {
            menuOptions.add("\t2) Fight!");
        }
        menuOptions.forEach(System.out::println);
    }

    public void doOption() {
        int option = getNumber();
        if (actions.containsKey(option)) {
            actions.get(option).execute();
        }
    }

    public int getNumber() {
        Scanner scanner = new Scanner(System.in);
        do{
            int input = scanner.nextInt();
        }while(input>2 && input<0);
        return input
    }
}

interface PlayerAction {
    void execute();
}

class DoNothingAction implements PlayerAction {
    @Override
    public void execute() {
        System.out.println("You do nothing.");
    }
}

class LookAroundAction implements PlayerAction {
    @Override
    public void execute() {
        System.out.println("You look around.");
    }
}

class FightAction implements PlayerAction {
    @Override
    public void execute() {
        System.out.println("You engage in combat!");
    }
}
___