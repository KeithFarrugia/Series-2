package nl.rug.aoop.command;

import java.util.Map;

/**
 * Command interface.
 */
public interface Command {
    /**
     * execute command which is overridden when implementing the interface.
     *
     * @param params takes in a Mapped string to object
     */
    void execute(Map<String, Object> params);
}
