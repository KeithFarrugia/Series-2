package nl.rug.aoop.initialization;

import nl.rug.aoop.messagequeue.Consumer;
import nl.rug.aoop.messagequeue.Message;
import nl.rug.aoop.messagequeue.MessageQueue;
import nl.rug.aoop.networking.MessageHandler;

/**
 * Responsible for polling a message queue for incoming messages and
 * delegating their handling to the message handler.
 */

public class MessageQueuePoller implements Runnable {
    private MessageHandler messageHandler;
    private MessageQueue messageQueue;
    private boolean running;

    /**
     * Constructs a new MessageQueuePoller.
     *
     * @param messageQueue   the queue from which to poll messages.
     * @param messageHandler the handler to process the polled messages.
     */
    public MessageQueuePoller(MessageQueue messageQueue, MessageHandler messageHandler) {
        this.messageHandler = messageHandler;
        this.messageQueue = messageQueue;
    }

    /**
     * Starts the polling process, processing each message using the message handler.
     */
    @Override
    public void run() {
        running = true;
        Consumer consumer = new Consumer(messageQueue);
        while (running) {
            Message message = consumer.poll();
            if (message != null) {
                messageHandler.handleMessage(message.toJson());
            }
        }
    }

    /**
     * Stops polling.
     *
     */
    public void stop() {
        this.running = false;
    }

}
