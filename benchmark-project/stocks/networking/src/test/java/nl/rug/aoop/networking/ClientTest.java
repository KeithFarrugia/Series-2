package nl.rug.aoop.networking;

import lombok.extern.slf4j.Slf4j;
import nl.rug.aoop.networking.Client.Client;
import org.junit.jupiter.api.Test;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.time.Duration;

import static org.awaitility.Awaitility.await;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit test for the client Handler
 **/
@Slf4j
class ClientTest {
    MessageHandler mockHandler = (message) -> {
    };
    private ResponseHandler responseHandler;
    private boolean serverStarted;
    private BufferedReader serverIn;
    private PrintWriter serverOut;
    private int serverPort;

    private void startTempServer() {
        new Thread(() -> {
            try {
                ServerSocket serverSocket = new ServerSocket(0);
                serverPort = serverSocket.getLocalPort();
                serverStarted = true;
                Socket socket = serverSocket.accept();
                serverIn = new BufferedReader(new InputStreamReader(socket.getInputStream()));
                serverOut = new PrintWriter(socket.getOutputStream(), true);
                log.info("Server started");
            } catch (IOException e) {
                log.error("Error on server start:", e);
            }
        }).start();
        await().atMost(Duration.ofSeconds(10)).until(() -> serverStarted);
    }

    @Test
    public void testConstructorWithRunningServer() {
        startTempServer();
        InetSocketAddress address = new InetSocketAddress("localhost", serverPort);
        Client client = new Client(address, mockHandler);
        assertTrue(client.isConnected());
    }

    @Test
    public void testConstructorWithoutRunningServer() {
        InetSocketAddress address = new InetSocketAddress("localhost", serverPort);
        Client client = new Client(address, mockHandler);
        assertTrue(client.isConnected());
    }

    @Test
    public void testInvalidPort() {
        startTempServer();
        try {
            // Attempt to create a Client with an invalid port should throw an error
            InetSocketAddress invalidAddress = new InetSocketAddress("localhost", -1);
            new Client(invalidAddress, mockHandler);

            fail("Expected an IllegalArgumentException to be thrown");
        } catch (IllegalArgumentException e) {
            // The test will pass if an IllegalArgumentException is thrown
            assertTrue(true);
        }
    }

    @Test
    public void testSendMessage() throws IOException, InterruptedException {
        startTempServer();

        InetSocketAddress address = new InetSocketAddress("localhost", serverPort);
        Client client = new Client(address, mockHandler);

        String messageToSend = "Hello";
        client.send(messageToSend);

        Thread.sleep(10);

        // Read the message received by the server
        String receivedMessage = serverIn.readLine();
        assertEquals(messageToSend, receivedMessage);

        client.terminate();
    }

    @Test
    public void testSendNullMessage() {
        startTempServer();
        InetSocketAddress address = new InetSocketAddress("localhost", serverPort);
        Client client = new Client(address, mockHandler);

        try {
            client.send(null);
            // Since the method catches the exception, assert that it does not throw it
            assertTrue(true);
        } catch (IllegalArgumentException e) {
            // If an exception is thrown, fail the test
            fail("Unexpected IllegalArgumentException: " + e.getMessage());
        }

        client.terminate();
    }

    @Test
    public void testSendEmptyMessage() {
        startTempServer();
        InetSocketAddress address = new InetSocketAddress("localhost", serverPort);
        Client client = new Client(address, mockHandler);

        String emptyMessage = "";
        try {
            client.send(emptyMessage);
            assertTrue(true);
        } catch (IllegalArgumentException e) {
            fail("Unexpected IllegalArgumentException: " + e.getMessage());
        }

        client.terminate();
    }

    @Test
    public void testRunReadSingleMessage() {
        startTempServer();

        InetSocketAddress address = new InetSocketAddress("localhost", serverPort);
        MessageHandler mockHandler = (message) -> assertEquals("Hello", message);

        Client client = new Client(address, mockHandler);
        new Thread(client).start();

        await().atMost(Duration.ofSeconds(10)).until(client::isRunning);
        assertTrue(client.isRunning());
        assertTrue(client.isConnected());

        String message = "Hello";
        serverOut.println(message);
        mockHandler.handleMessage(message);
    }

    @Test
    public void terminateClient() {
        startTempServer();
        InetSocketAddress address = new InetSocketAddress("localhost", serverPort);
        Client client = new Client(address, mockHandler);

        assertTrue(client.isConnected());

        client.terminate();

        assertFalse(client.isConnected());
    }

}