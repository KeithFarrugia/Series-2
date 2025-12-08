package nl.rug.aoop.initialization;

import nl.rug.aoop.model.Encoder;
import nl.rug.aoop.model.Stock;
import nl.rug.aoop.model.StockExchange;
import nl.rug.aoop.model.Trader;
import nl.rug.aoop.networking.Server.ClientHandler;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.mockito.Mockito.*;

public class UpdateSenderTest {
    Stock dummyStock;
    Stock dummyStock2;
    Trader dummyTrader;
    List<Stock> stockList;


    private UpdateSender updateSender;
    private StockExchange stockExchange;

    @BeforeEach
    public void setup() {
        stockExchange = mock(StockExchange.class);
        updateSender = new UpdateSender(stockExchange);

        Map<String, Integer> ownedSharesMap = new HashMap<>();
        ownedSharesMap.put("north korea", 23);
        dummyTrader = new Trader("1", "TestTrader", 452783, ownedSharesMap);

        // return the trader
        when(stockExchange.getTraderByIndex(anyInt())).thenReturn(dummyTrader);

        // Mock a stock list for the stock exchange
        dummyStock = new Stock("TS", "TestStock", 123000, 123);
        dummyStock2 = new Stock("TS2", "TestStock2", 123002, 1232);
        stockList = new ArrayList<>();
        stockList.add(dummyStock);
        stockList.add(dummyStock2);

        // return the stockList
        when(stockExchange.getAllStocks()).thenReturn(stockList);
    }

    @Test
    public void testSendUpdatesToClients() {
        List<ClientHandler> clients = new ArrayList<>();
        ClientHandler mockClient = mock(ClientHandler.class);
        clients.add(mockClient);
        Encoder encoder = new Encoder(dummyTrader, stockList);
        updateSender.sendUpdatesToClients(clients);
        verify(mockClient).send(encoder.traderString());
        verify(mockClient).send(encoder.stocksString());

    }
}
