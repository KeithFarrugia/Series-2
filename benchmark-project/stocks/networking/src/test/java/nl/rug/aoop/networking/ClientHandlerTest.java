package nl.rug.aoop.networking;

import lombok.extern.slf4j.Slf4j;
import nl.rug.aoop.networking.Server.ClientHandler;
import org.junit.jupiter.api.Test;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit test for the client Handler
 **/
@Slf4j
public class ClientHandlerTest {
    MessageHandler messageHandler = (message) -> {
    };
    ServerSocket serverSocket;
    Socket clientSocket;
    private ClientHandler clientHandler;
    private BufferedReader in;
    private PrintWriter out;

    public void setUp() throws IOException {
        serverSocket = new ServerSocket(0);
        final int serverPort = serverSocket.getLocalPort();

        new Thread(() -> {
            try {
                clientSocket = new Socket("localhost", serverPort);
                in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
                out = new PrintWriter(clientSocket.getOutputStream(), true);
                log.info("Client socket started");
            } catch (IOException e) {
                log.error("Client connection error", e);
            }
        }).start();

        Socket serverSideClientSocket = serverSocket.accept();
        clientHandler = new ClientHandler(serverSideClientSocket, 1, messageHandler);
    }

    public void tearDown() {
        try {
            if (clientHandler != null) {
                clientHandler.terminate();
            }
            if (clientSocket != null && !clientSocket.isClosed()) {
                clientSocket.close();
            }
            if (serverSocket != null && !serverSocket.isClosed()) {
                serverSocket.close();
            }
            if (in != null) {
                in.close();
            }
            if (out != null) {
                out.close();
            }
        } catch (IOException e) {
            log.error("Error while closing sockets", e);
        }
    }

    @Test
    public void testSendMessage() throws IOException, InterruptedException {
        setUp();
        String message = "Hello";
        Thread.sleep(50);
        if (in != null) {
            clientHandler.send(message);
            log.info(message);
            assertEquals(message, in.readLine());
        } else {
            fail("BufferedReader 'in' was not properly initialized");
        }
        clientHandler.terminate();
        tearDown();
    }


    @Test
    public void testSendNullMessage() throws IOException {
        setUp();
        try {
            clientHandler.send(null);
            assertTrue(true);
        } catch (IllegalArgumentException e) {
            fail("Unexpected IllegalArgumentException: " + e.getMessage());
        }

        clientHandler.terminate();
        tearDown();
    }

    @Test
    public void testSendEmptyMessage() throws IOException {
        setUp();
        String emptyMessage = "";
        try {
            clientHandler.send(emptyMessage);
            assertTrue(true);
        } catch (IllegalArgumentException e) {
            fail("Unexpected IllegalArgumentException: " + e.getMessage());
        }

        clientHandler.terminate();
        tearDown();
    }

    @Test
    public void testTerminateWhenRunning() throws IOException {
        setUp();
        clientHandler.terminate();
        assertFalse(clientHandler.isRunning());
    }

    @Test
    public void testTerminateWhenNotRunning() {
        assertThrows(NullPointerException.class, () -> clientHandler.terminate());
        assertFalse(clientHandler != null && clientHandler.isRunning());
    }

    @Test
    public void testConstructor() throws IOException {
        setUp();
        assertEquals(1, clientHandler.getClientId());
        assertEquals(messageHandler, clientHandler.getMessageHandler());
        assertEquals(serverSocket.getLocalPort(), clientHandler.getSocket().getLocalPort());
    }

    @Test
    public void testIsRunning() throws IOException {
        setUp();

        Thread thread = new Thread(clientHandler);
        thread.start();

        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            fail("Thread sleep interrupted");
        }

        assertTrue(clientHandler.isRunning());
    }
}
