package nl.rug.aoop.messagequeue.commands;

import lombok.extern.slf4j.Slf4j;
import nl.rug.aoop.command.Command;
import nl.rug.aoop.messagequeue.Message;
import nl.rug.aoop.messagequeue.MessageQueue;

import java.util.Map;

/**
 * This is an idea of how a command used to poll (retrieve) a message from a message queue might resemble.
 */
@Slf4j
public class MqPollCommand implements Command {
    private final MessageQueue messageQueue;

    /**
     * Constructor that takes the messageQueue from which messages will be polled.
     *
     * @param messageQueue The messageQueue from which messages will be polled.
     */
    public MqPollCommand(MessageQueue messageQueue) {
        this.messageQueue = messageQueue;
    }

    @Override
    public void execute(Map<String, Object> params) {
        // Poll a message from the queue
        Message polledMessage = messageQueue.dequeue();

        if (polledMessage != null) {
            log.info("Polled message: {}", polledMessage.getBody());

        } else {
            log.info("queue empty");
        }
    }
}
