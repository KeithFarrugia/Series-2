package nl.rug.aoop.networking.Server;

import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import nl.rug.aoop.networking.MessageHandler;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;

/**
 * Client Handler class to receive and send messages from the client.
 */

@Slf4j
public class ClientHandler implements Runnable {
    @Getter
    private final Socket socket;
    private final int id;
    @Getter
    private final MessageHandler messageHandler;
    private final BufferedReader in;
    private final PrintWriter out;
    private boolean running = false;

    /**
     * Constructor for class.
     *
     * @param socket         socket to initialize
     * @param id             give the Client an ID
     * @param messageHandler Implementation of messageHandler
     * @throws IOException in case of error
     */
    public ClientHandler(Socket socket, int id, MessageHandler messageHandler) throws IOException {
        this.id = id;
        this.messageHandler = messageHandler;
        this.socket = socket;
        out = new PrintWriter(socket.getOutputStream(), true);
        in = new BufferedReader(new InputStreamReader((socket.getInputStream())));
    }

    /**
     * Run the client handler.
     * While running continuously called buffered reader's readLine
     * Delegate message handling to the messageHandler and log messages received from clients
     */
    @Override
    public void run() {
        log.info("ClientHandler for client " + id + " started");
        out.println("Logged in with ID: " + id);
        try {
            running = true;
            while (running) {
                String fromClient = in.readLine();
                messageHandler.handleMessage(fromClient);
                if (fromClient == null) {
                    log.warn("Received null message from client " + id);
                    terminate();
                    break;
                }
                messageHandler.handleMessage(fromClient);
            }
        } catch (IOException e) {
            log.error("Error reading string from client with id: " + id, e);
        }
        log.info("ClientHandler for client " + id + " stopped");
    }
     
    /**
     * Terminate connection with client.
     */
    public void terminate() {
        try {
            // Close IO streams and the socket
            if (in != null) {
                in.close();
            }
            if (out != null) {
                out.close();
            }
            if (socket != null && !socket.isClosed()) {
                socket.close();
            }
        } catch (IOException e) {
            log.error("Error while closing resources.", e);
        }
        running = false;
    }

    /**
     * Sending a valid message to the client.
     *
     * @param message is a string to send to the server
     */
    public void send(String message) {
        try {
            if (message == null || message.equals("")) {
                throw new IllegalArgumentException("Invalid Input");
            }
        } catch (IllegalArgumentException e) {
            log.error("Exception: " + e.getMessage());
        }
        out.println(message);
        log.info(message);
    }

    /**
     * Getter for id.
     *
     * @return id
     */
    public int getClientId() {
        return id;
    }

    /**
     * Getter for running.
     *
     * @return running
     */
    public boolean isRunning() {
        return running;
    }
}
