package nl.rug.aoop.model;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class TestTrader {

    private Trader trader;

    @BeforeEach
    public void setUp() {
        Map<String, Integer> ownedShares = new HashMap<>();
        ownedShares.put("AAPL", 10);
        trader = new Trader("1", "Jason Derulo", 5000.0, ownedShares);
    }

    @Test
    public void testGetId() {
        assertEquals("1", trader.getId());
    }

    @Test
    public void testGetName() {
        assertEquals("Jason Derulo", trader.getName());
    }

    @Test
    public void testGetFunds() {
        assertEquals(5000.0, trader.getFunds());
    }

    @Test
    public void testGetOwnedShares() {
        Map<String, Integer> expectedShares = new HashMap<>();
        expectedShares.put("AAPL", 10);
        assertEquals(expectedShares, trader.getOwnedShares());
    }

    @Test
    public void testSetFunds() {
        trader.setFunds(6000.0);
        assertEquals(6000.0, trader.getFunds());
    }

    @Test
    public void testAddTransaction() {
        Transaction transaction = new Transaction(
                "1",
                "AAPL",
                5,
                150.0,
                "testType",
                LocalDateTime.now()
        );
        trader.addTransaction(transaction);
        List<Transaction> transactions = trader.getTransactions();
        assertEquals(1, transactions.size());
        assertTrue(transactions.contains(transaction));
    }
}
