// Global variables for File System Access API handles
let directoryHandle = null;
let currentFileHandle = null;

// DOM elements
const openDirBtn = document.getElementById('open-dir-btn');
const saveBtn = document.getElementById('save-btn');
const loadClonesBtn = document.getElementById('load-clones-btn');
const closeClonesBtn = document.getElementById('close-clones-btn');
const editorContent = document.getElementById('editor-content');
const lineNumbers = document.getElementById('line-numbers');
const fileTree = document.getElementById('file-tree');
const fileStatus = document.getElementById('file-status');
const currentFileDisplay = document.getElementById('current-file-display');
const unsavedIndicator = document.getElementById('unsaved-indicator');
const messageBox = document.getElementById('message-box');

// New DOM elements for the clone view
const standardEditorView = document.getElementById('standard-editor-view');
const cloneAnalysisView = document.getElementById('clone-analysis-view');
const cloneList = document.getElementById('clone-list');
const cloneDiffContainer = document.getElementById('clone-diff-container');


// State tracking
let isUnsaved = false;
let currentClonesData = null;

/**
 * Utility function to display non-critical messages.
 */
function showMessage(text, duration = 3000) {
    messageBox.textContent = text;
    // Reset classes and set to yellow for default message
    messageBox.className = 'fixed bottom-4 right-4 p-4 rounded-lg shadow-xl transition-opacity duration-300 opacity-100 bg-yellow-400 text-gray-800';

    clearTimeout(window.messageTimeout);
    window.messageTimeout = setTimeout(() => {
        // Fade out
        messageBox.classList.remove('opacity-100');
        messageBox.classList.add('opacity-0', 'pointer-events-none');
    }, duration);
}

/**
 * Switches between the standard editor view and the clone analysis view.
 * @param {boolean} showCloneView - True to show clone view, false to show editor.
 */
function toggleView(showCloneView) {
    if (showCloneView) {
        standardEditorView.classList.add('hidden');
        cloneAnalysisView.classList.remove('hidden');
        cloneAnalysisView.classList.add('flex'); // Ensure it uses flex layout when visible
        loadClonesBtn.classList.add('hidden');
    } else {
        standardEditorView.classList.remove('hidden');
        cloneAnalysisView.classList.add('hidden');
        loadClonesBtn.classList.remove('hidden');
    }
}

/**
 * Recursively reads and builds the file tree structure.
 */
async function buildFileTree(dirHandle, path = '') {
    const ul = document.createElement('ul');
    ul.className = 'ml-3 space-y-1';

    for await (const entry of dirHandle.values()) {
        const li = document.createElement('li');
        li.className = 'cursor-pointer hover:bg-gray-200 p-1 rounded transition-colors';

        if (entry.kind === 'file') {
            const filename = entry.name;
            li.innerHTML = `<span class="text-blue-600">📄 ${filename}</span>`;
            li.dataset.filename = filename;
            li.dataset.path = path;
            li.onclick = () => openFile(entry); 
        } else if (entry.kind === 'directory') {
            const dirName = entry.name;
            const newPath = path ? `${path}/${dirName}` : dirName;
            
            const toggler = document.createElement('span');
            toggler.className = 'text-gray-900 font-semibold inline-block w-full';
            toggler.innerHTML = `📁 ${dirName}`;
            toggler.onclick = toggleDirectory;
            li.appendChild(toggler);

            const subTree = await buildFileTree(entry, newPath);
            subTree.style.display = 'none';
            li.appendChild(subTree);
        }
        ul.appendChild(li);
    }
    return ul;
}

/**
 * Toggles the visibility of a subdirectory.
 */
function toggleDirectory(event) {
    event.stopPropagation();
    const parentLi = event.target.closest('li');
    if (parentLi) {
        const ul = parentLi.querySelector('ul');
        if (ul) {
            const isHidden = ul.style.display === 'none';
            ul.style.display = isHidden ? 'block' : 'none';
            
            const iconSpan = event.target;
            if (iconSpan) {
                const text = iconSpan.textContent;
                iconSpan.textContent = isHidden ? '📂 ' + text.substring(2) : '📁 ' + text.substring(2);
            }
        }
    }
}

/**
 * Loads the content of the selected file into the editor.
 */
async function openFile(fileHandle) {
    if (isUnsaved) {
        showMessage("You have unsaved changes. Please save or discard manually before opening a new file.", 5000);
        return;
    }

    try {
        if (await verifyPermission(fileHandle, false) === false) {
            showMessage("Read permission denied for this file.");
            return;
        }

        const file = await fileHandle.getFile();
        const contents = await file.text();

        currentFileHandle = fileHandle;
        editorContent.value = contents;
        currentFileDisplay.textContent = fileHandle.name;
        editorContent.disabled = false;
        saveBtn.disabled = false;

        updateLineNumbers();
        setUnsaved(false);
        showMessage(`File opened: ${fileHandle.name}`);

    } catch (error) {
        console.error('Error opening file:', error);
        showMessage(`Could not open file: ${fileHandle.name}. Error: ${error.message}`);
        currentFileHandle = null;
        editorContent.value = '';
        currentFileDisplay.textContent = '-- No file open --';
    }
}

/**
 * Saves the current editor content back to the file system.
 */
async function saveFile() {
    if (!currentFileHandle) {
        showMessage("No file is currently open to save.");
        return;
    }

    try {
        if (await verifyPermission(currentFileHandle, true) === false) {
            showMessage("Write permission denied. Cannot save.");
            return;
        }

        const writable = await currentFileHandle.createWritable();
        await writable.write(editorContent.value);
        await writable.close();

        setUnsaved(false);
        showMessage(`File saved successfully: ${currentFileHandle.name}`, 4000);

    } catch (error) {
        console.error('Error saving file:', error);
        showMessage(`Failed to save file: ${error.message}`);
    }
}

/**
 * Prompts the user to select a directory and builds the file tree.
 */
async function openDirectory() {
    if ('showDirectoryPicker' in window) {
        try {
            directoryHandle = await window.showDirectoryPicker();
            fileStatus.textContent = `Directory: ${directoryHandle.name}`;
            fileTree.innerHTML = '<p class="text-gray-500">Loading directory structure...</p>';

            const tree = await buildFileTree(directoryHandle);
            fileTree.innerHTML = '';
            fileTree.appendChild(tree);

            showMessage(`Successfully opened directory: ${directoryHandle.name}`);

        } catch (error) {
            console.error('Directory access denied or error:', error);
            if (error.name === 'AbortError') {
                 showMessage(`Directory selection cancelled.`);
            } else {
                 showMessage(`Access denied or error: ${error.message}`);
            }
        }
    } else {
        showMessage("Your browser does not support the File System Access API. Try Chrome, Edge, or Opera.", 6000);
    }
}

/**
 * Verifies read or read/write permissions for a handle.
 */
async function verifyPermission(handle, writable) {
    const opts = {};
    if (writable) {
        opts.mode = 'readwrite';
    }

    if ((await handle.queryPermission(opts)) === 'granted') {
        return true;
    }

    if ((await handle.requestPermission(opts)) === 'granted') {
        return true;
    }

    return false;
}


/**
 * Updates the content of the line number column based on the textarea content.
 * FIX: Switched to using <div> elements for each line number to ensure
 * precise vertical alignment with the editor content, relying on 'style.css'.
 */
function updateLineNumbers() {
    const content = editorContent.value;
    const lineCount = content.split('\n').length;
    let numbersHtml = '';
    for (let i = 1; i <= lineCount; i++) {
        // Use a div wrapper for reliable line height and vertical alignment
        numbersHtml += `<div>${i}</div>`; 
    }
    lineNumbers.innerHTML = numbersHtml; // Use innerHTML
    syncScroll();
}

/**
 * Handles the synchronization of line numbers and content scrolling.
 */
function syncScroll() {
    lineNumbers.scrollTop = editorContent.scrollTop;
}

/**
 * Sets the unsaved status indicator.
 */
function setUnsaved(status) {
    isUnsaved = status;
    const name = currentFileHandle?.name || 'Untitled';
    if (status) {
        unsavedIndicator.classList.remove('hidden');
        document.title = `*Web Code Editor - ${name}`;
    } else {
        unsavedIndicator.classList.add('hidden');
        document.title = `Web Code Editor - ${name}`;
    }
}
/**
 * Reads the content of a file within the opened directory based on its path using FSA.
 * This function iterates through the path segments, which is the most robust way
 * to handle deep paths with the File System Access API.
 * * @param {string} filePath - The file path (e.g., 'src/main/java/org/sigmetrics/Duplication.java')
 * @returns {Promise<string>} The content of the file or an error message.
 */
async function getFileContentByPath(filePath) {
    if (!directoryHandle) {
        return `// Error: No project directory opened. File content for ${filePath} cannot be retrieved.`;
    }

    try {
        // 1. Clean the path and split into segments
        const pathSegments = filePath.split('/').filter(p => p.length > 0);
        let currentHandle = directoryHandle;

        // 2. Traverse the directory segments (all except the last one, which is the file)
        for (let i = 0; i < pathSegments.length - 1; i++) {
            const dirName = pathSegments[i];
            
            // Crucial: Use getDirectoryHandle for all intermediate parts
            currentHandle = await currentHandle.getDirectoryHandle(dirName);
        }

        // 3. Get the final file handle
        const fileName = pathSegments[pathSegments.length - 1];
        const fileHandle = await currentHandle.getFileHandle(fileName);
        
        // --- File Reading and Permission Check ---

        if (await verifyPermission(fileHandle, false) === false) {
             return `// Error: Read permission denied for file: ${filePath}`;
        }
        
        const file = await fileHandle.getFile();
        return await file.text();

    } catch (error) {
        // The detailed error message indicates the exact point of failure (e.g., if 'src' doesn't exist)
        console.error(`Failed to read file ${filePath} from directory:`, error);
        return `// Error: Failed to read file: ${filePath}. File not found or inaccessible. Error detail: ${error.message}`;
    }
}
/**
 * Loads the clone analysis JSON data. It prioritizes loading the file from the
 * user's opened project directory via the File System Access API, otherwise
 * it falls back to fetching a static file via HTTP (for testing).
 */
async function loadSampleJson() {
    if (!directoryHandle) {
        showMessage("Please open the project directory first using the 'Open Project Directory' button.", 6000);
        return;
    }
    showMessage("Loading clone analysis data...");
    try {
        const CLONE_FILE_NAME = 'clones.json';
        let responseData = null;
        let source = 'Fetch (Static)';

        if (directoryHandle) {
            // Strategy 1: Use File System Access API (Preferred for local project data)
            try {
                const cloneFileHandle = await directoryHandle.getFileHandle(CLONE_FILE_NAME);
                if (await verifyPermission(cloneFileHandle, false) === false) {
                     throw new Error(`Permission denied for ${CLONE_FILE_NAME}`);
                }
                const file = await cloneFileHandle.getFile();
                const contents = await file.text();
                responseData = JSON.parse(contents);
                source = 'FSA (Local Project)';

            } catch (error) {
                // If the file is not found in the root of the opened folder, fall back.
                console.warn(`FSA failed to find ${CLONE_FILE_NAME}. Error: ${error.message}. Falling back to fetch.`);
                // Fall through to Strategy 2
            }
        }
        
        if (!responseData) {
            // Strategy 2: Use standard fetch (Required when running via server without opened directory)
            const response = await fetch(`./${CLONE_FILE_NAME}`);

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}. Make sure the file exists.`);
            }
            responseData = await response.json();
        }

        currentClonesData = responseData;
        
        renderCloneAnalysis();
        toggleView(true); // Switch to the clone view
        showMessage(`Successfully loaded ${currentClonesData.clones.length} clone group(s). Source: ${source}`);

    } catch (error) {
        console.error('Error loading clone data:', error);
        showMessage(`Failed to load clone analysis: ${error.message}`, 8000);
    }
}

/**
 * Renders the full clone analysis view with summaries and side-by-side diffs.
 */
function renderCloneAnalysis() {
    if (!currentClonesData) return;

    // Clear previous content
    cloneList.innerHTML = '';
    cloneDiffContainer.innerHTML = '';

    // Render clone summaries
    currentClonesData.clones.forEach((cloneGroup, index) => {
        const summaryDiv = document.createElement('div');
        summaryDiv.className = 'bg-blue-50 border border-blue-200 p-3 rounded-lg cursor-pointer hover:bg-blue-100 transition-colors';
        summaryDiv.innerHTML = `
            <p class="font-bold text-blue-700">Clone Group #${index + 1}: ${cloneGroup.type}</p>
            <p class="text-sm text-gray-600">Fragment Length: ${cloneGroup.fragmentLength} lines. Duplicates: ${cloneGroup.locations.length}</p>
        `;
        // Pass the entire clone group object to the click handler
        summaryDiv.onclick = () => renderCloneFragments(cloneGroup);
        cloneList.appendChild(summaryDiv);
    });

    // Automatically render the first clone group
    if (currentClonesData.clones.length > 0) {
        renderCloneFragments(currentClonesData.clones[0]);
    }
}

/**
 * Renders the side-by-side view for a specific clone group.
 */
async function renderCloneFragments(cloneGroup) {
    cloneDiffContainer.innerHTML = '<div class="text-gray-500 p-4 w-full text-center">Loading code fragments...</div>';

    // We only support side-by-side (2 fragments) for this simple viewer
    const locations = cloneGroup.locations.slice(0, 2);

    // Fetch all file contents concurrently
    const fileContentsPromises = locations.map(location => getFileContentByPath(location.filePath));
    const fileContents = await Promise.all(fileContentsPromises);
    
    cloneDiffContainer.innerHTML = ''; // Clear loading message

    locations.forEach((location, index) => {
        // Use custom class .clone-fragment-view which is fixed in style.css
        const fragmentContainer = document.createElement('div');
        fragmentContainer.className = 'clone-fragment-view'; 

        // 1. Header
        const header = document.createElement('div');
        header.className = 'clone-header bg-gray-700 text-white p-2 font-mono text-xs truncate rounded-t-lg';
        header.textContent = `Fragment ${index + 1} | ${location.filePath} (Lines ${location.startLine}-${location.endLine})`;
        fragmentContainer.appendChild(header);

        // 2. Code Area (The main content container, flex)
        const codeArea = document.createElement('div');
        // This div is needed to correctly apply the CSS grid layout defined in style.css
        codeArea.className = 'code-area-inner flex-grow flex overflow-hidden'; 

        // Get the lines of code from the fetched file content
        const fileContent = fileContents[index];
        // console.log(`Rendering fragment from file: ${location.filePath}`); // Keep for debugging
        // console.log(fileContent); // Keep for debugging
        const fileLines = fileContent.split('\n');

        // Get clone line boundaries
        const startLine = location.startLine;
        const endLine = location.endLine;

        // 4. Content Block (Code using DIV/PRE for highlighting)
        const contentBlock = document.createElement('div');
        // Use the .clone-content-display class (we'll define this in CSS)
        contentBlock.className = 'clone-content-display';

        let codeHtml = '';
        // Iterate over ALL lines of the file content
        for (let i = 0; i < fileLines.length; i++) {
            const lineNumber = i + 1; // 1-based line number
            const lineContent = fileLines[i];
            
            // Check if the current line is within the clone range
            const highlightClass = (lineNumber >= startLine && lineNumber <= endLine)
                ? ' clone-highlight'
                : '';

            // Wrap each line in a <pre> or <div> to control styling and preserve whitespace
            codeHtml += `<div class="code-line${highlightClass}"><pre>${lineContent}</pre></div>`;
        }

        contentBlock.innerHTML = codeHtml;


        // 3. Line Numbers (Needs to show ALL lines)
        const fragmentLineNumbers = document.createElement('div');
        fragmentLineNumbers.className = 'clone-lines';

        let numbersHtml = '';
        // Iterate over ALL lines for line numbers
        for (let i = 1; i <= fileLines.length; i++) {
            const highlightClass = (i >= startLine && i <= endLine)
                ? ' clone-highlight'
                : '';
            // Apply highlight class to the line number if it's cloned
            numbersHtml += `<div class="${highlightClass}">${i}</div>`; 
        }
        fragmentLineNumbers.innerHTML = numbersHtml;

        // Use a scrollable container for the code block
        const scrollWrapper = document.createElement('div');
        scrollWrapper.className = 'code-scroll-wrapper'; // New class for scrollable area
        scrollWrapper.appendChild(contentBlock);
        scrollWrapper.tabIndex = 0; // Make scrollable and focusable

        // Add scroll listener to sync line numbers with content
        scrollWrapper.addEventListener('scroll', (e) => {
            fragmentLineNumbers.scrollTop = e.target.scrollTop;
        });

        // Combine line numbers and content block
        codeArea.appendChild(fragmentLineNumbers);
        codeArea.appendChild(scrollWrapper);
        fragmentContainer.appendChild(codeArea);

        cloneDiffContainer.appendChild(fragmentContainer);
    });
}


// --- Event Listeners ---

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