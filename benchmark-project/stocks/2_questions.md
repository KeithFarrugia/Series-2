# Question 1

In the assignment, you had to create a `MessageHandler` interface. Please answer the following two questions:

1. Describe the benefits of using this `MessageHandler` interface. (~50-100 words)
2. Instead of creating an implementation of `MessageHandler` that invokes a command handler, we could also pass the command handler to the client/server directly without the middle man of the `MessageHandler` implementation. What are the implications of this? (~50-100 words)

___

**Answers**:
1. By using the MessageHandler interface we gain several benefits such as A: Flexibility and re-usability: allows developers to create various implementations of MessageHandler which may be more tailored to their application's unique message processing needs thus enhancing code re-usability. B: Extensibility and Modularity : similar logic to before, leaving message handling to have it's own interface allows for the network to be tailored to the developer's requirements. C: Encapsulation: by encapsulating functionality of handling messages to this interface it promotes encapsulation thus serving as a well-defined point for integrating message related functionality.#

2. Pretty much the opposite of what was said before. This reduces flexibility and code re-usability as well as introducing a loss of abstraction, meaning that the network project isn't as easily scalable as if it had it's own interface.
 This can also pose several testing challenges as unit testing the client and server becomes more tedious because they'll be more closely coupled together. To summarise removing the MessageHandler interface may not be the best of ideas as it introduces the negatives mentioned.
___

# Question 2

One of your colleagues wrote the following class:

```java
public class RookieImplementation {

    private final Car car;

    public RookieImplementation(Car car) {
        this.car = car;
    }

    public void carEventFired(String carEvent) {
        if("steer.left".equals(carEvent)) {
            car.steerLeft();
        } else if("steer.right".equals(carEvent)) {
            car.steerRight();
        } else if("engine.start".equals(carEvent)) {
            car.startEngine();
        } else if("engine.stop".equals(carEvent)) {
            car.stopEngine();
        } else if("pedal.gas".equals(carEvent)) {
            car.accelerate();
        } else if("pedal.brake".equals(carEvent)) {
            car.brake();
        }
    }
}
```

This code makes you angry. Briefly describe why it makes you angry and provide the improved code below.

___

**Answer**:

This code makes us angry because it isn't scalable, as for every time a new car event is introduced you wwould need to change the RookieImplementation class to handle it. A better implementation would be to utilise a design pattern like the Command Pattern. Which encapsulates each car event as a separate command, allowing you to add new commands without modifying existing code hence making it more extensible and maintainable. 
Improved code:
```java
import java.util.HashMap;
import java.util.Map;

// Creating an interface
interface CarCommand {
    void execute();
}
// Implementations of CarCommand(s) for various car events
class SteerLeftCommand implements CarCommand {
    private final Car car;

    public SteerLeftCommand(Car car) {
        this.car = car;
    }

    @Override
    public void execute() {
        car.steerLeft();
    }
}

class EngineStartCommand implements CarCommand {
    private final Car car;

    public EngineStartCommand(Car car) {
        this.car = car;
    }

    @Override
    public void execute() {
        car.startEngine();
    }
}
class EngineStopCommand implements CarCommand {
    private final Car car;

    public EngineStopCommand(Car car) {
        this.car = car;
    }

    @Override
    public void execute() {
        car.stopEngine();
    }
}
class GasPedalCommand implements CarCommand {
    private final Car car;

    public GasPedalCommand(Car car) {
        this.car = car;
    }

    @Override
    public void execute() {
        car.accelerate();
    }
}
class BrakePedalCommand implements CarCommand {
    private final Car car;

    public BrakePedalCommand(Car car) {
        this.car = car;
    }

    @Override
    public void execute() {
        car.brake();
    }
}

//Improved class using the command map
public class ImprovedCarController {

    private final Car car;
    private final Map<String, CarCommand> commandMap;

    public ImprovedCarController(Car car) {
        this.car = car;
        this.commandMap = new HashMap<>();

        // Initialize the command map with supported car events
        commandMap.put("steer.left", new SteerLeftCommand(car));
        commandMap.put("steer.right", new SteerRightCommand(car));
        commandMap.put("engine.start", new EngineStartCommand(car));
        commandMap.put("engine.stop", new EngineStopCommand(car));
        commandMap.put("pedal.gas", new GasPedalCommand(car));
        commandMap.put("pedal.brake", new BrakePedalCommand(car));
    }

    public void carEventFired(String carEvent) {
        CarCommand command = commandMap.get(carEvent);
        if (command != null) {
            command.execute();
        }
    }
}
```
___

# Question 3

You have the following exchange with a colleague:

> **Colleague**: "Hey, look at this! It's super handy. Pretty simple to write custom experiments."

```java
class Experiments {
    public static Model runExperimentA(DataTable dt) {
        CommandHandler commandSequence = new CleanDataTableCommand()
            .setNext(new RemoveCorrelatedColumnsCommand())
            .setNext(new TrainSVMCommand());

        Config config = new Options();
        config.set("broadcast", true);
        config.set("svmdatatable", dt);

        commandSequence.handle(config);

        return (Model) config.get("svmmodel");
    }

    public static Model runExperimentB() {
        CommandHandler commandSequence = new CleanDataTableCommand()
            .setNext(new TrainSGDCommand());

        Config config = new Options();
        config.set("broadcast", true);
        config.set("sgddatatable", dt);

        commandSequence.handle(config);

        return (Model) config.get("sgdmodel");
    }
}
```

> **Colleague**: "I could even create this method to train any of the models we have. Do you know how Jane did it?"

```java
class Processor {
    public static Model getModel(String algorithm, DataTable dt) {
        CommandHandler commandSequence = new TrainSVMCommand()
            .setNext(new TrainSDGCommand())
            .setNext(new TrainRFCommand())
            .setNext(new TrainNNCommand());

        Config config = new Options();
        config.set("broadcast", false);
        config.set(algorithm + "datatable", dt);

        commandSequence.handle(config);

        return (Model) config.get(algorithm + "model");
    }
}
```

> **You**: "Sure! She is using the command pattern. Easy indeed."
>
> **Colleague**: "Yeah. But look again. There is more; she uses another pattern on top of it. I wonder how it works."

1. What is this other pattern? What advantage does it provide to the solution? (~50-100 words)

2. You know the code for `CommandHandler` has to be a simple abstract class in this case, probably containing four methods:
- `CommandHandler setNext(CommandHandler next)` (implemented in `CommandHandler`),
- `void handle(Config config)` (implemented in `CommandHandler`),
- `abstract boolean canHandle(Config config)`,
- `abstract void execute(Config config)`.

Please provide a minimum working example of the `CommandHandler` abstract class.

___

**Answer**:

1.
We believe the other pattern used must be the "Chain of responsability" pattern as the CommandHandler instances are chained together, and each command in the chain has the ability to handle a specific part of the request and pass it on to the next command in the chain if necessary. Thus this allows for sequential execution of commands and improving the program's handling of tasks by different command objects which led us to understand the other pattern as "Chain of responsability".

2.
```java
abstract class CommandHandler {
    private CommandHandler next;

    public CommandHandler setNext(CommandHandler next) {
        this.next = next;
        return next;
    }

    public void handle(Config config) {
        if (canHandle(config)) {
            execute(config);
        } else if (next != null) {
            next.handle(config);
        }
    }

    protected abstract boolean canHandle(Config config);
    protected abstract void execute(Config config);
}
```
___
