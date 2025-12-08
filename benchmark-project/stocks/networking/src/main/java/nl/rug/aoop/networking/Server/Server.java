package nl.rug.aoop.networking.Server;

import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import nl.rug.aoop.networking.MessageHandler;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Server class.
 */
@Slf4j
public class Server implements Runnable {
    private final ExecutorService service;
    @Getter
    private final MessageHandler messageHandler;
    private List<ClientHandler> clientHandlers = new ArrayList<>();
    private ServerSocket serverSocket;
    private boolean running = false;
    private int id = 0;

    /**
     * Server constructor.
     * Starts the service and sets messageHandler.
     *
     * @param port           port to listen on
     * @param messageHandler implementation of messageHandler
     */
    public Server(int port, MessageHandler messageHandler) {
        this.messageHandler = messageHandler;
        service = Executors.newCachedThreadPool();
        try {
            serverSocket = new ServerSocket(port);
        } catch (IOException e) {
            log.error("Invalid port: " + e.getMessage());
        }
    }

    /**
     * getter for port.
     *
     * @return port
     */
    public int getPort() {
        return this.serverSocket.getLocalPort();
    }

    /**
     * Run the server.
     * Log which clients connect with their id and spawn a clienthandler
     * for each client
     */
    @Override
    public void run() {
        running = true;
        log.info("Server started on port " + serverSocket.getLocalPort());
        while (running) {
            try {
                Socket socket = this.serverSocket.accept();
                log.info("Client: " + id + " connected");// Show if a client connected
                ClientHandler clientHandler = new ClientHandler(socket, id, messageHandler); //Spawn a ClientHandler
                clientHandlers.add(clientHandler);
                this.service.submit(clientHandler);
                id++;
            } catch (IOException e) {
                if (serverSocket.isClosed()) {
                    log.info("Server socket closed, stopping server.");
                    break;
                }
                log.error("Something went wrong with spawning ClientHandler : ", e);
            }
        }
        log.info("Server stopped");
    }

    /**
     * End connection.
     * close sockets and set running to false
     */
    public void terminate() {
        this.service.shutdownNow(); // Use shutdownNow() to interrupt any running tasks.
        try {
            if (!serverSocket.isClosed()) {
                serverSocket.close();
            }
        } catch (IOException e) {
            log.error("Error while closing server socket: ", e);
        }
        clientHandlers.clear();
        log.info("Server terminated");
        running = false;
    }

    /**
     * getter for running.
     *
     * @return running
     */
    public boolean isRunning() {
        return this.running;
    }

    public List<ClientHandler> getClientHandlers() {
        return clientHandlers;
    }
}