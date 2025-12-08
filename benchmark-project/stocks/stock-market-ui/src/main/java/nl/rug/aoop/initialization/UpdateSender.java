package nl.rug.aoop.initialization;

import lombok.extern.slf4j.Slf4j;
import nl.rug.aoop.model.Encoder;
import nl.rug.aoop.model.StockExchange;
import nl.rug.aoop.model.Trader;
import nl.rug.aoop.networking.Server.ClientHandler;

import java.util.List;

/**
 * Responsible for sending periodic updates about the stock exchange
 * to connected clients.
 */
@Slf4j
public class UpdateSender {

    private final StockExchange stockExchange;

    /**
     * an instance of StockExchange is changed in order to be able to access the information we are sending.
     *
     * @param stockExchange the instance of StockExchange
     */
    public UpdateSender(StockExchange stockExchange) {
        this.stockExchange = stockExchange;
    }

    /**
     * Sends the updates to the clients.
     *
     * @param clients the clientHandlers that we will use to send to their respective clients.
     */
    public void sendUpdatesToClients(List<ClientHandler> clients) {
        for (ClientHandler client : clients) {
            try {
                Thread.sleep(3000);
            } catch (InterruptedException e) {
                log.info("Error sleeping");
            }
            Encoder encoder = new Encoder((Trader) stockExchange.getTraderByIndex(client.getClientId()),
                    stockExchange.getAllStocks());
            client.send(encoder.traderString());
            client.send(encoder.stocksString());
            log.info("Trader sent: " + encoder.traderString());
            log.info("Stocks sent: " + encoder.stocksString());
        }
    }
}
