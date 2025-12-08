package nl.rug.aoop.command;

import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import java.util.HashMap;
import java.util.Map;

/**
 * Command Handler class which will be used to register and
 * execute commands.
 */
@Slf4j
public class CommandHandler {
    @Getter
    private final Map<String, Command> commandMap;

    /**
     * Default constructor that initializes an empty hashmap.
     */
    public CommandHandler() {
        this.commandMap = new HashMap<>();
    }

    /**
     * Constructor that accepts an initial map of commands.
     *
     * @param initialCommands The initial map of commands to register.
     */
    public CommandHandler(Map<String, Command> initialCommands) {
        this.commandMap = new HashMap<>(initialCommands);
    }

    /**
     * Registers a command with the command handler.
     *
     * @param command      The name for the command.
     * @param commandClass The command it refers to.
     */
    public void registerCommand(String command, Command commandClass) {
        this.commandMap.put(command, commandClass);
    }

    /**
     * Executes commands.
     *
     * @param command The command that refers to the object.
     * @param params  The parameters associated with the command.
     */
    public void execute(String command, Map<String, Object> params) {
        if (commandMap.containsKey(command)) {
            Command command1 = commandMap.get(command);
            command1.execute(params);
        }else {
            log.info("MessageHandler could not handle your message");
        }
    }
}
