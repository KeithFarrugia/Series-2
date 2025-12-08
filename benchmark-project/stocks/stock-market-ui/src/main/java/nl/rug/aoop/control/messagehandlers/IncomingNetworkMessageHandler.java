package nl.rug.aoop.control.messagehandlers;

import nl.rug.aoop.command.Command;
import nl.rug.aoop.initialization.factories.MqCommandFactory;
import nl.rug.aoop.messagequeue.commands.NetworkMessage;
import nl.rug.aoop.networking.MessageHandler;

import java.util.HashMap;
import java.util.Map;

/**
 * This class is used in order to handle orders using the command handler after polling from the queue in stockApp.
 */

public class IncomingNetworkMessageHandler implements MessageHandler {
    private final MqCommandFactory mqCommandFactory;

    /**
     * This constructor  method is used to assign a command factory.
     *
     * @param mqCommandFactory the command factory
     */
    public IncomingNetworkMessageHandler(MqCommandFactory mqCommandFactory) {
        this.mqCommandFactory = mqCommandFactory;
    }

    /**
     * This method turns the network message back to a message from its string form and packs what is inside it to
     * a map to redirect it to the command handler, sending the header a command.
     *
     * @param sMessage the message to take in
     */
    @Override
    public void handleMessage(String sMessage) {
        NetworkMessage message = NetworkMessage.fromJson(sMessage);
        String commandName = message.getCommandName();
        Map<String, Object> params = new HashMap<>();
        params.put("header", commandName);
        params.put("body", message.getMessage());

        Command command = mqCommandFactory.getCommand(commandName);

        command.execute(params);
    }
}
