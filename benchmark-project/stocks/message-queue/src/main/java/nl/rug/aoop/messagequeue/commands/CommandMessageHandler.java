package nl.rug.aoop.messagequeue.commands;

import nl.rug.aoop.command.CommandHandler;
import nl.rug.aoop.networking.MessageHandler;

import java.util.HashMap;
import java.util.Map;

/**
 * The CommandMessageHandler class implements the MessageHandler
 * interface to handle incoming network messages. It extracts the command and content from
 * the wrapped message, adds the extracted details into a map (alongside a communicator which
 * allows messages to be sent back), and then redirects the command to the appropriate CommandHandler.
 *
 */
public class CommandMessageHandler implements MessageHandler {
    private final CommandHandler commandHandler;

    /**
     * Constructs a new instance of CommandMessageHandler that will use the provided
     * CommandHandler instance to process the command extracted from the network message.
     *
     * @param commandHandler The command handler responsible for processing the extracted commands.
     */
    public CommandMessageHandler(CommandHandler commandHandler) {
        this.commandHandler = commandHandler;
    }

    @Override
    public void handleMessage(String message) {
        NetworkMessage networkMessage = NetworkMessage.fromJson(message);
        String command = networkMessage.getCommandName();
        Map<String, Object> params = new HashMap<>();
        params.put("header", networkMessage.getCommandName());
        params.put("body", networkMessage.getMessage());
        commandHandler.execute(command, params);
    }
}
