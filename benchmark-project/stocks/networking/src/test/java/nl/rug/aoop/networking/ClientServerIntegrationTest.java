package nl.rug.aoop.networking;

import nl.rug.aoop.networking.Client.Client;
import nl.rug.aoop.networking.Server.Server;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.net.InetSocketAddress;
import java.time.Duration;

import static org.awaitility.Awaitility.await;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

/**
 * Integration test for the networking module
 */
public class ClientServerIntegrationTest {
    static Server server;  // Declare the server as a static variable
    static MessageHandler mockMessageHandler;
    ResponseHandler mockResponseHandler;
    Thread client1Thread;
    Thread client2Thread;
    private Client client1;
    private Client client2;

    @BeforeAll
    public static void setUpServer() {
        // Create the server only once
        mockMessageHandler = mock(MessageHandler.class);
        server = new Server(8080, mockMessageHandler);
        Thread serverThread = new Thread(server);
        serverThread.start();

        // Wait for the server to start
        await().atMost(Duration.ofSeconds(10)).until(server::isRunning);
    }

    @BeforeEach
    public void setUpClients() {
        mockResponseHandler = mock(ResponseHandler.class);
        // Using mockito for simplicity's sake to initialize a communicator and message handler
        // Create client 1 and client 2
        client1 = new Client(new InetSocketAddress("localhost", 8080), mockMessageHandler);
        client2 = new Client(new InetSocketAddress("localhost", 8080), mockMessageHandler);
        client1Thread = new Thread(client1);
        client2Thread = new Thread(client2);
    }

    @Test
    public void testClientServerConnection() throws InterruptedException {
        // Start client threads
        client1Thread.start();
        client2Thread.start();
        Thread.sleep(10);

        // Check if both clients are connected to the server
        assertTrue(client1.isConnected());
        assertTrue(client2.isConnected());
    }

    @Test
    public void testSendAndGetMessage() throws InterruptedException {
        // Start client threads
        Thread.sleep(10);

        // Send a message from "client2" as if it's from the server
        String messageFromClient2 = "Hello from Client 2!";

        // Simulate receiving the message on client1
        client1.getMessageHandler().handleMessage(messageFromClient2);

        // Allow the message to propagate
        Thread.sleep(10);

        // Verify that client1's message handler correctly handles the received message
        verify(mockMessageHandler).handleMessage(messageFromClient2);
    }
}
