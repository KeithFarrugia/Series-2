package nl.rug.aoop.control.messagehandlers;

import nl.rug.aoop.command.Command;
import nl.rug.aoop.initialization.factories.OrderCommandFactory;
import nl.rug.aoop.messagequeue.Message;
import nl.rug.aoop.networking.MessageHandler;

import java.util.HashMap;
import java.util.Map;

/**
 * Handles incoming order messages, processes them, and executes the associated command.
 */
public class IncomingOrderMessageHandler implements MessageHandler {
    private final OrderCommandFactory orderCommandFactory;

    /**
     * Initializes a new instance of the IncomingOrderMessageHandler class.
     *
     * @param orderCommandFactory Factory responsible for producing the corresponding command objects for orders.
     */
    public IncomingOrderMessageHandler(OrderCommandFactory orderCommandFactory) {
        this.orderCommandFactory = orderCommandFactory;
    }

    /**
     * Handles the received message. Parses the message to extract the command and its parameters,
     * and then executes the corresponding command.
     *
     * @param sMessage The serialized message content.
     */
    @Override
    public void handleMessage(String sMessage) {
        Message message = Message.fromJson(sMessage);
        String commandName = message.getHeader();
        Map<String, Object> params = new HashMap<>();
        params.put("OrderType", commandName);
        params.put("Order", message.getBody());

        Command command = orderCommandFactory.getCommand(commandName);

        command.execute(params);
    }
}
