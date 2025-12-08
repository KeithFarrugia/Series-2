package nl.rug.aoop.messagequeue.commands;

import lombok.extern.slf4j.Slf4j;
import nl.rug.aoop.command.Command;
import nl.rug.aoop.messagequeue.Message;
import nl.rug.aoop.messagequeue.MessageQueue;

import java.util.Map;

/**
 * This is the command used to put an incoming message into a queue.
 *
 */
@Slf4j
public class MqPutCommand implements Command {
    private final MessageQueue messageQueue;

    /**
     * The constructor is given the messageQueue that the message will be put in.
     *
     * @param messageQueue the messageQueue that the message will be put in.
     */
    public MqPutCommand(MessageQueue messageQueue) {
        this.messageQueue = messageQueue;
    }

    @Override
    public void execute(Map<String, Object> params) {
        String messageString = params.get("body").toString();
        Message message = Message.fromJson(messageString);
        messageQueue.enqueue(message);
    }
}
