package nl.rug.aoop.messagequeue.commands;

import com.google.gson.Gson;
import lombok.Getter;

/**
 * This class is used to wrap an instance of the message class in order to send it
 * over the network alongside a command.
 *
 */
public class NetworkMessage {
    private static final Gson GSON = new Gson();
    @Getter
    private String commandName;
    @Getter
    private String message;

    /**
     * Class constructor to initialize a network message.
     *
     * @param commandName the command name written as a string
     * @param message the message to be sent in a json format
     */
    public NetworkMessage(String commandName, String message) {
        this.commandName = commandName;
        this.message = message;
    }

    /**
     * Create a NetworkMessage for polling a message.
     *
     * @return The NetworkMessage for polling.
     */
    public static NetworkMessage createPollMessage() {
        return new NetworkMessage("MqPoll", "");
    }

    /**
     * Turn a NetworkMessage from JSON to a NetworkMessage instance.
     *
     * @param json the string that will be converted from
     * @return the NetworkMessage
     */
    public static NetworkMessage fromJson(String json) {
        return GSON.fromJson(json, NetworkMessage.class);
    }

    /**
     * Turn the NetworkMessage into a JSON string.
     *
     * @return the json string
     */
    public String toJson() {
        return GSON.toJson(this);
    }
}
