module stock.market.ui {
    requires static lombok;
    exports nl.rug.aoop.model;
    exports nl.rug.aoop.control;
    exports nl.rug.aoop.initialization;
    requires org.slf4j;
    requires java.desktop;
    requires com.formdev.flatlaf;

    requires messagequeue;
    requires networking;
    requires command;
    requires com.google.gson;
    requires org.mockito;
    opens nl.rug.aoop.model to com.fasterxml.jackson.databind, com.google.gson;
    opens nl.rug.aoop.control to com.google.gson;
    opens nl.rug.aoop.initialization to com.fasterxml.jackson.databind, com.google.gson;
    exports nl.rug.aoop.model.managers;
    opens nl.rug.aoop.model.managers to com.fasterxml.jackson.databind, com.google.gson;
    exports nl.rug.aoop.model.loaders;
    opens nl.rug.aoop.model.loaders to com.fasterxml.jackson.databind, com.google.gson;
    exports nl.rug.aoop.initialization.factories;
    opens nl.rug.aoop.initialization.factories to com.fasterxml.jackson.databind, com.google.gson;
    exports nl.rug.aoop.control.messagehandlers;
    opens nl.rug.aoop.control.messagehandlers to com.google.gson;

    requires java.net.http;
    requires jdk.httpserver;
    requires util;
    opens nl.rug.aoop.webview.data to com.google.gson;

}