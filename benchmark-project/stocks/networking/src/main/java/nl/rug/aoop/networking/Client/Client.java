package nl.rug.aoop.networking.Client;

import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import nl.rug.aoop.networking.MessageHandler;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.InetSocketAddress;
import java.net.Socket;

/**
 * Class for the client which implements Runnable and a
 * communicator to eventually be able to send messages back.
 */
@Slf4j
public class Client implements Runnable {

    @Getter
    private final MessageHandler messageHandler;
    @Getter
    private boolean running = false;
    private Socket socket;
    private BufferedReader in;
    private PrintWriter out;
    @Getter
    private boolean connected;

    /**
     * Constructor for class which uses initSocket to help initialize
     * IO and the socket.
     *
     * @param address        address to connect socket to
     * @param messageHandler implementation of messageHandler to pass
     */
    public Client(InetSocketAddress address, MessageHandler messageHandler) {
        try {
            initSocket(address);
        } catch (IOException e) {
            log.error("Couldn't init socket " + e.getMessage());
        }
        this.messageHandler = messageHandler;
        connected = true;
    }

    /**
     * Helper method to initialize the socket and IO streams for the constructor.
     *
     * @param address to connect to
     * @throws IOException in case a socket couldn't be initialized
     */
    private void initSocket(InetSocketAddress address) throws IOException {
        socket = new Socket("localhost", address.getPort());
        in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
        out = new PrintWriter(socket.getOutputStream(), true);

        if (!socket.isConnected()) {
            throw new IOException("Socket not connected");
        }
    }

    @Override
    public void run() {
        running = true;
        log.info("Started");
        while (running) {
            try {
                // Read messages from server
                String incomingMessage = in.readLine();

                if (incomingMessage == null) {
                    throw new ClassNotFoundException("Null message");
                }
                // Handle incoming Messages using an implementation of messageHandler
                messageHandler.handleMessage(incomingMessage);
            } catch (IOException e) {
                log.error("Could not receive message " + e.getMessage());
                terminate();
            } catch (ClassNotFoundException e) {
                log.error("Error encountered: " + e.getMessage());
            }
        }
    }

    /**
     * Send valid message to server.
     *
     * @param message is the string to send
     */
    public void send(String message) {
        try {
            if (message == null) {
                terminate();
                return;
            } else if (message.equals("")) {
                throw new IllegalArgumentException("Invalid Input");
            }
        } catch (IllegalArgumentException e) {
            log.error("Exception: " + e.getMessage());
        }
        // If message is not null or empty send it to the server
        out.println(message);

    }

    /**
     * Method to end connection to server.
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
        connected = false;
        running = false;
        log.info("client closed");
    }
}
