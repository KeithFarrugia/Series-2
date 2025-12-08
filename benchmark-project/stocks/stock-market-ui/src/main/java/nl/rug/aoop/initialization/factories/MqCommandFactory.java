package nl.rug.aoop.initialization.factories;

import nl.rug.aoop.command.Command;
import nl.rug.aoop.messagequeue.MessageQueue;
import nl.rug.aoop.messagequeue.commands.MqPutCommand;

/**
 * Provides command objects specifically for MessageQueue operations.
 */
public class MqCommandFactory implements CommandFactory {
    private final MessageQueue messageQueue;

    /**
     * Initializes a new instance of the MqCommandFactory class.
     *
     * @param messageQueue The message queue to operate upon.
     */
    public MqCommandFactory(MessageQueue messageQueue) {
        this.messageQueue = messageQueue;
    }

    /**
     * Creates command objects based on order type.
     *
     * @param orderType the type of the order.
     * @return the command object.
     */
    @Override
    public Command getCommand(String orderType) {
        if (orderType.equals("MqPut")) {
            return new MqPutCommand(messageQueue);
        }
        throw new IllegalArgumentException("Invalid order type: " + orderType);
    }
}
