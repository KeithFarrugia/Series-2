package com.example.ui;

import javax.swing.JFrame;
import java.awt.Dimension;

public class GameWindow extends JFrame {
    
    private BattlePanel battlePanel;

    public GameWindow(BattlePanel panel) {
        super("Clone Demo RPG - Graphical UI");
        this.battlePanel = panel;
        
        // Setup the frame
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setPreferredSize(new Dimension(800, 600)); // Set a reasonable size
        
        // Add the panel that handles all rendering
        add(battlePanel);
        
        pack();
        setLocationRelativeTo(null); // Center the window
        setVisible(true);
    }
    
    // Method to pass actions to the panel
    public void displayAction(String attackerName, String targetName, String actionType) {
        battlePanel.startAttackAnimation(attackerName, targetName, actionType);
    }
}