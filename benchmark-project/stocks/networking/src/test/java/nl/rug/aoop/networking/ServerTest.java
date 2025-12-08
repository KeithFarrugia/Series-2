package nl.rug.aoop.networking;

import nl.rug.aoop.networking.Server.Server;
import org.junit.Test;
import org.junit.jupiter.api.Assertions;

import java.time.Duration;

import static org.awaitility.Awaitility.await;
import static org.junit.Assert.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Unit test for the server to see if it's functions work
 **/
public class ServerTest {
    Thread serverThread;
    MessageHandler messageHandler = (message) -> {
    };
    private ResponseHandler responseHandler;
    private Server server;

    public void startServer() {
        MessageHandler messageHandler = (message) -> Assertions.assertEquals("Hello", message);

        int port = 5613;
        server = new Server(port, messageHandler);
        serverThread = new Thread(server);
        serverThread.start();
        await().atMost(Duration.ofSeconds(10)).until(() -> server.isRunning());
    }

    public void shutDown() {
        serverThread.interrupt();
        server.terminate();
    }

    @Test
    public void testConstructor() {
        startServer();
        assertEquals(server.getPort(), 5613);
        Assertions.assertDoesNotThrow(() -> {
            server.getMessageHandler().handleMessage("Hello");
            messageHandler.handleMessage("Hello");
        });
        shutDown();
    }

    @Test
    public void testIsRunning() {
        startServer();

        assertTrue(server.isRunning());
        shutDown();
    }

    @Test
    public void testPortInitialization() {
        startServer();
        assertEquals(5613, server.getPort());
        shutDown();
    }

    @Test
    public void testServerTerminationWithRunningServer() {
        startServer();
        shutDown();
        assertFalse(server.isRunning());
    }

    @Test
    public void testServerTerminationWithoutRunningServer() {
        try {
            shutDown();
        } catch (NullPointerException e) {
            assertTrue(true); // can't terminate a server that isn't running
        }
    }
}