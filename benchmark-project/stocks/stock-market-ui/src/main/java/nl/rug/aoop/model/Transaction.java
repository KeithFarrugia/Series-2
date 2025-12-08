package nl.rug.aoop.model;

import java.time.LocalDateTime;

/**
 * Record to store transaction history.
 *
 * @param traderId         the trader's id.
 * @param stockSymbol      the stock symbol of the transaction.
 * @param sharesTraded     the amount of shares bought/sold.
 * @param transactionPrice the price of the sell/buy.
 * @param orderType        LimitBuy or LimitSell order.
 * @param timestamp        time of transaction.
 */
public record Transaction(
        String traderId,
        String stockSymbol,
        int sharesTraded,
        double transactionPrice,
        String orderType,
        LocalDateTime timestamp
) {
}


