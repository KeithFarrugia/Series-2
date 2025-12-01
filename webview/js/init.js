


// 1. Open Directory Button
openDirBtn.addEventListener('click', openDirectory);

// 2. Save Button
saveBtn.addEventListener('click', saveFile);

// 3. Load Clones Button
loadClonesBtn.addEventListener('click', loadSampleJson);

// 4. Close Clones Button
closeClonesBtn.addEventListener('click', () => toggleView(false));

// 5. Editor Content and Line Number Sync
editorContent.addEventListener('input', () => {
    updateLineNumbers();
    if (currentFileHandle) {
        setUnsaved(true);
    }
});

// 6. Scroll synchronization
editorContent.addEventListener('scroll', syncScroll);

// 7. Keyboard Shortcut for Save (Ctrl+S / Cmd+S)
document.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === 's') {
        e.preventDefault();
        saveFile();
    }
});

// 8. Initial setup
window.addEventListener('load', () => {
    updateLineNumbers(); 
    if (!('showDirectoryPicker' in window)) {
         showMessage("Warning: File System Access API not supported in this browser. Clone viewing capabilities will be limited.", 8000);
    }
});

document.addEventListener('DOMContentLoaded', () => {
    const filterControls = document.getElementById('clone-filter-controls');
    if (filterControls) {
        filterControls.addEventListener('change', applyCloneFilter);
    }

    const filterHeader = document.getElementById('filter-accordion-header');
    const filterIcon = document.getElementById('filter-accordion-icon');
    
    // Check if elements exist (only available in the clone view)
    if (filterHeader && filterControls && filterIcon) {
        
        // 1. Initial State: Start collapsed to save vertical space
        // We set this here in JS to ensure the filters work before the view is toggled
        filterControls.classList.add('hidden');
        filterIcon.classList.remove('rotate-180'); // Icon pointing down when closed

        // 2. Click Handler
        filterHeader.addEventListener('click', () => {
            filterControls.classList.toggle('hidden');
            // Toggle icon rotation (180deg when open, 0deg when closed)
            filterIcon.classList.toggle('rotate-180'); 
        });
        
        // Ensure the filter change listener is still attached to the controls
        filterControls.addEventListener('change', applyCloneFilter);
    }
});