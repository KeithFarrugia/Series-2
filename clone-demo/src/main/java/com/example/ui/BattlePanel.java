package com.example.ui;

import javax.swing.JPanel;
import javax.swing.Timer;
import java.awt.Graphics;
import java.awt.Color;
import java.awt.Image;
import java.net.URL;

import javax.imageio.ImageIO;

public class BattlePanel extends JPanel implements java.awt.event.ActionListener {
    
    private static final int ANIMATION_FRAMES = 35; // Increased frames for longer animation
    private static final int UNIT_SIZE = 100;
    private static final int GROUND_Y = 350;

    private Timer animationTimer;
    private int animationFrame = 0;
    private boolean animating = false;
    
    private String currentAttacker;
    private String currentTarget;
    private String currentAction;
    
    // Placeholder Images
    private Image heroImage;
    private Image mageImage;
    private Image goblinImage;
    private Image orcImage;
    private Image physicalAttackEffectImage;
    private Image magicAttackEffectImage;

    public BattlePanel() {
        setBackground(Color.DARK_GRAY);
        loadImages();
        // Timer for the animation loop
        animationTimer = new Timer(50, this);
    }

    private Image loadImage(String path) {
        URL imgURL = getClass().getClassLoader().getResource(path);
        if (imgURL == null) {
            System.err.println("Resource not found: " + path);
            return null;
        }
        try {
            return ImageIO.read(imgURL);
        } catch (Exception e) {
            System.err.println("Error loading image from URL: " + path);
            e.printStackTrace();
            return null;
        }
    }

    private void loadImages() {
        heroImage = loadImage("hero.png");
        mageImage = loadImage("mage.png"); 
        goblinImage = loadImage("goblin.png");
        orcImage = loadImage("orc.png");
        physicalAttackEffectImage = loadImage("slash.png");
        magicAttackEffectImage = loadImage("cast.png");
    }
    
    // Called by the GameWindow to start an animation
    public void startAttackAnimation(String attacker, String target, String action) {
        this.currentAttacker = attacker;
        this.currentTarget = target;
        this.currentAction = action;
        this.animationFrame = 0;
        this.animating = true;
        
        // Start the timer to trigger repaint()
        animationTimer.start();
    }

    // Handles the animation frame update
    @Override
    public void actionPerformed(java.awt.event.ActionEvent e) {
        if (animating) {
            animationFrame++;
            if (animationFrame > ANIMATION_FRAMES) {
                animationTimer.stop();
                animating = false;
                // Notify the BattleSimulator that the animation is finished
                synchronized (this) {
                    this.notify(); 
                }
            }
            repaint();
        }
    }
    
    // Core drawing method
    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        
        // 1. Draw Static Background/Characters
        g.setColor(Color.GREEN.darker());
        g.fillRect(50, 450, 700, 100); // Ground
        
        // --- DRAW HERO ---
        if (heroImage != null) {
            g.drawImage(heroImage, 100, GROUND_Y, UNIT_SIZE, UNIT_SIZE, this);
        } else {
            g.setColor(Color.BLUE); g.fillRect(100, GROUND_Y, UNIT_SIZE, UNIT_SIZE);
            g.setColor(Color.WHITE); g.drawString("HERO", 120, GROUND_Y + 50);
        }
        
        // --- DRAW MAGE ---
        if (mageImage != null) {
            g.drawImage(mageImage, 250, GROUND_Y, UNIT_SIZE, UNIT_SIZE, this);
        } else {
            g.setColor(Color.CYAN); g.fillRect(250, GROUND_Y, UNIT_SIZE, UNIT_SIZE);
            g.setColor(Color.WHITE); g.drawString("MAGE", 270, GROUND_Y + 50);
        }

        // --- DRAW GOBLIN ---
        if (goblinImage != null) {
            g.drawImage(goblinImage, 450, GROUND_Y, UNIT_SIZE, UNIT_SIZE, this);
        } else {
            g.setColor(Color.YELLOW); g.fillRect(450, GROUND_Y, UNIT_SIZE, UNIT_SIZE);
            g.setColor(Color.BLACK); g.drawString("GOBLIN", 460, GROUND_Y + 50);
        }
        
        // --- DRAW ORC ---
        if (orcImage != null) { 
            g.drawImage(orcImage, 600, GROUND_Y, UNIT_SIZE, UNIT_SIZE, this);
        } else {
            // Fallback: Use the red block
            g.setColor(Color.RED); g.fillRect(600, GROUND_Y, UNIT_SIZE, UNIT_SIZE);
            g.setColor(Color.WHITE); g.drawString("ORC", 620, GROUND_Y + 50);
        }

        // 2. Draw Animation (FIXED to use image/color)
        if (animating) {
            int startX = currentAttacker.equals("Arin") ? 150 : 650;
            int endX = currentTarget.equals("Goblin") ? 450 : 600;
            
            // Calculate current X position: linear interpolation
            int xPos = startX + (endX - startX) * animationFrame / ANIMATION_FRAMES;
            
            // Determine which effect image to use
            Image effectImage = null;
            Color fallbackColor = null;
            
            if (currentAction.equals("Cast")) {
                effectImage = magicAttackEffectImage;
                fallbackColor = Color.MAGENTA;
            } else { // Slash, Smash, etc.
                effectImage = physicalAttackEffectImage;
                fallbackColor = Color.ORANGE;
            }

            // Draw the effect image or a better color if not loaded
            if (effectImage != null) {
                g.drawImage(effectImage, xPos, 300, 50, 50, this);
            } else {
                // Fallback: Use the appropriate color
                g.setColor(fallbackColor);
                g.fillOval(xPos, 300, 30, 30);
            }
            
            g.setColor(Color.WHITE);
            g.drawString(currentAttacker + " performing " + currentAction + "!", 300, 50);
        }
        
        // 3. Draw UI Text/HP Bars
        g.setColor(Color.WHITE);
        g.drawString("Hero HP: XX/XX", 100, 320);
        g.drawString("Mage HP: XX/XX", 250, 320);
        g.drawString("Goblin HP: XX/XX", 450, 320);
        g.drawString("Orc HP: XX/XX", 600, 320);
    }
    
    // This method is key to pausing the battle logic
    public void waitForAnimation() {
        // CLONE TYPE 4: Semantic clone of a standard Thread.sleep() or delay loop
        try {
            // Wait until the animation has finished (notified by actionPerformed)
            synchronized (this) {
                while (animating) { 
                    this.wait();
                }
            }
        } catch (InterruptedException e) {
            // Handle interrupted exception gracefully
            Thread.currentThread().interrupt();
            System.err.println("Animation interrupted.");
        }
    }
}