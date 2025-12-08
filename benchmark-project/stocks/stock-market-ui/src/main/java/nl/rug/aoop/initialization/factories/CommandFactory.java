package nl.rug.aoop.initialization.factories;

import nl.rug.aoop.command.Command;

/**
 * Provides a factory interface for creating command objects based on order types.
 */
public interface CommandFactory {
    /**
     * Creates command objects based on order type.
     *
     * @param orderType the type of the order.
     * @return the command object.
     */
    Command getCommand(String orderType);
}
