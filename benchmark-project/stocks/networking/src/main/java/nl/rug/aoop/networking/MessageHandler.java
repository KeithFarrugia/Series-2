package nl.rug.aoop.networking;

/**
 * Interface for the messageHandler.
 */
public interface MessageHandler {
    /**
     * handleMessage method to be overridden when classes
     * implement the interface.
     *
     * @param message the message to take in
     */
    void handleMessage(String message);
}


