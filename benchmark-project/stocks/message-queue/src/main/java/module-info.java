module messagequeue {
    requires org.slf4j;
    requires org.mockito;
    requires static lombok;
    requires com.google.gson;
    requires networking;
    requires command;
    opens nl.rug.aoop.messagequeue to com.google.gson;
    exports nl.rug.aoop.messagequeue;
    exports nl.rug.aoop.messagequeue.commands;
    opens nl.rug.aoop.messagequeue.commands to com.google.gson;
}