package nl.rug.aoop.networking;

/**
 * This interface is for communication operations.
 * Classes implementing this interface provide implementations
 * for sending messages and terminating their communication.
 */
public interface ResponseHandler {

    /**
     * Sends a specified message.
     *
     * @param message The message to be sent.
     */
    void send(String message);

    /**
     * Terminates the communication, any resources or connections associated
     * with the communication process is closed.
     */
    void terminate();
}
