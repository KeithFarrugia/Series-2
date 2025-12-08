package nl.rug.aoop.command;

import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class CommandHandlerTest {
    private CommandHandler commandHandler;

    @Test
    public void testDefaultConstructor() {
        commandHandler = new CommandHandler();
        assertTrue(commandHandler.getCommandMap().isEmpty());
    }

    @Test
    public void testConstructorWithInitialCommands() {
        Map<String, Command> initialCommands = new HashMap<>();
        initialCommands.put("boy1", params -> {
        });
        initialCommands.put("boy1ButBigger", params -> {
        });

        CommandHandler handlerWithInitialCommands = new CommandHandler(initialCommands);
        assertEquals(initialCommands.size(), handlerWithInitialCommands.getCommandMap().size());
    }

    @Test
    public void testRegisterAndExecuteCommand() {
        commandHandler = new CommandHandler();
        Command sampleCommand = params -> {
            System.out.println("Executing sample command with params: " + params);
        };

        commandHandler.registerCommand("caveman", sampleCommand);

        Map<String, Object> params = new HashMap<>();
        params.put("android", "superiority");
        params.put("lucky number", 42);

        commandHandler.execute("caveman", params);
        //assertEquals("Executed caveman", result);
    }

    @Test
    public void testExecuteUnknownCommand() {
        commandHandler = new CommandHandler();
        Map<String, Object> params = new HashMap<>();
        params.put("param1", "value1");

        // Execute an unknown command
        commandHandler.execute("I don't exist", params);
    }
}
