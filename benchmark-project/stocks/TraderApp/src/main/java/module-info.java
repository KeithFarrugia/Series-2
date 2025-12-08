module nl.rug.aoop {
    requires javafx.controls;
    requires javafx.fxml;
    requires stock.market.ui;
    requires messagequeue;
    requires networking;
    requires command;
    requires org.mockito;
    opens nl.rug.aoop to javafx.fxml;
    exports nl.rug.aoop;
}