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
    const newContent = editorContent.value;
    const lineCount = newContent.split('\n').length;
    // 1. Retrieve the original text to search for
    const originalFragmentText = editorContent.dataset.originalFragmentText;
    
    // 2. Find the start index of the original fragment in the new content
    const startIndex = newContent.indexOf(originalFragmentText);

    let newStartLine = -1;
    let newEndLine = -1;

    if (startIndex !== -1) {
        // 3. Calculate the new start line number (1-based)
        // Count the number of newlines occurring BEFORE the match
        newStartLine = (newContent.substring(0, startIndex).match(/\n/g) || []).length + 1;
        
        // 4. Calculate the new end line number
        const fragmentLineCount = (originalFragmentText.match(/\n/g) || []).length + 1;
        newEndLine = newStartLine + fragmentLineCount - 1;
    } 

    let numbersHtml = '';
    for (let i = 1; i <= lineCount; i++) {
        numbersHtml += `<div class=>${i}</div>`;
    }
    lineNumbers.innerHTML = numbersHtml;
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

    applyCloneFilter();

    // Clear previous content
    cloneList.innerHTML = '';
    cloneDiffContainer.innerHTML = '';

    // Render clone summaries
    currentClonesData.clones.forEach((cloneGroup, index) => {
        // Determine the CSS class based on the type number (1, 2, or 3)
        const typeClass = `summary-type-${cloneGroup.type}`;
        
        const summaryDiv = document.createElement('div');
        // Use the new class for the left border/visual distinction
        summaryDiv.className = `bg-blue-50 border border-blue-200 p-3 rounded-lg cursor-pointer hover:bg-blue-100 transition-colors ${typeClass}`;
        
        // Use the 'name' field from the JSON
        summaryDiv.innerHTML = `
            <p class="font-bold text-blue-700">Clone Group #${index + 1}: ${cloneGroup.name}</p>
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

function updateCloneLineNumbers(contentElement, lineNumbersElement, cloneType) {
    // 1. Get the current edited content as plain text using the helper
    // The previous implementation relied on a TEXTAREA, this relies on the DIV helper.
    const newContent = getEditableContentText(contentElement);
    const lineCount = newContent.split('\n').length;
    
    // 2. Retrieve the original text to search for
    const originalFragmentText = contentElement.dataset.originalFragmentText;
    
    // 3. Find the start index of the original fragment in the new content
    const startIndex = newContent.indexOf(originalFragmentText);

    const typeClass = `clone-type-${cloneType}`;

    let newStartLine = -1;
    let newEndLine = -1;

    if (startIndex !== -1) {
        // 4. Calculate the new start line number (1-based)
        // Count the number of newlines occurring BEFORE the match
        newStartLine = (newContent.substring(0, startIndex).match(/\n/g) || []).length + 1;
        
        // 5. Calculate the new end line number
        const fragmentLineCount = (originalFragmentText.match(/\n/g) || []).length + 1;
        newEndLine = newStartLine + fragmentLineCount - 1;
    } 
    
    // 6. Regenerate line numbers with the new highlight range
    let numbersHtml = '';
    for (let i = 1; i <= lineCount; i++) {
        // Apply the dynamic type class if it's within the calculated range
        const highlightClass = (i >= newStartLine && i <= newEndLine)
            ? ` ${typeClass}`
            : '';
        numbersHtml += `<div class="code-line-number${highlightClass}">${i}</div>`;
    }
    lineNumbersElement.innerHTML = numbersHtml;

    const codeLines = contentElement.querySelectorAll('.code-line');

    codeLines.forEach((lineDiv, i) => {
        const lineNumber = i + 1; // Line number based on array index (1-based)
        
        // 7. Remove all existing clone-type classes
        lineDiv.classList.remove('clone-type-1', 'clone-type-2', 'clone-type-3');
        
        // 8. Apply the new type class if within the bounds
        if (lineNumber >= newStartLine && lineNumber <= newEndLine) {
            lineDiv.classList.add(typeClass);
        }
    });
}

/**
 * Extracts the full, clean text content from the contenteditable div, 
 * correctly preserving newlines represented by the inner <div> structure.
 * @param {HTMLElement} contentElement - The contenteditable div (.clone-content-display).
 * @returns {string} The reconstructed code content.
 */
function getEditableContentText(contentElement) {
    // Select all the line wrapper divs
    const lineElements = contentElement.querySelectorAll('.code-line');
    
    // Extract the text content from each line's <pre> element
    const lines = Array.from(lineElements).map(lineDiv => {
        // Use .textContent on the inner <pre> element to get the raw code line
        const pre = lineDiv.querySelector('pre');
        return pre ? pre.textContent : '';
    });

    // Join all lines with a newline character
    return lines.join('\n');
}

/**
 * Saves the edited content of a single clone fragment back to its source file.
 * @param {string} filePath - The path to the file being edited (relative to project root).
 * @param {HTMLElement} contentElement - The contenteditable div containing the new code.
 */
async function saveCloneFragment(filePath, contentElement) {
    if (!directoryHandle) {
        showMessage("Error: No project directory is open.", 5000);
        return;
    }
    
    // 1. Get the current edited content
    const newContent = getEditableContentText(contentElement);
    
    // 2. Get the file handle via path traversal (using the robust function you just added)
    let fileHandle = null;
    try {
        // We reuse the robust path traversal logic from getFileContentByPath (without reading content)
        const pathSegments = filePath.split('/').filter(p => p.length > 0);
        let currentHandle = directoryHandle;

        for (let i = 0; i < pathSegments.length - 1; i++) {
            currentHandle = await currentHandle.getDirectoryHandle(pathSegments[i]);
        }
        
        const fileName = pathSegments[pathSegments.length - 1];
        fileHandle = await currentHandle.getFileHandle(fileName);

    } catch (error) {
        console.error('Failed to get file handle for saving:', error);
        showMessage(`Failed to locate file ${filePath} for saving.`, 5000);
        return;
    }

    // 3. Perform save operation
    try {
        if (await verifyPermission(fileHandle, true) === false) {
            showMessage("Write permission denied. Cannot save file.", 5000);
            return;
        }

        const writable = await fileHandle.createWritable();
        await writable.write(newContent);
        await writable.close();

        showMessage(`File saved successfully: ${filePath}`, 4000);

    } catch (error) {
        console.error('Error saving file:', error);
        showMessage(`Failed to save file: ${error.message}`, 8000);
    }
}

function applyCloneFilter() {
    if (!currentClonesData || !currentClonesData.clones) return;

    // Get the status of the checkboxes
    const checkedTypes = Array.from(document.querySelectorAll('#clone-filter-controls input[type="checkbox"]:checked'))
        .map(input => parseInt(input.value)); // Get the checked values as numbers

    // Filter the original clone data
    const filteredClones = currentClonesData.clones.filter(cloneGroup => 
        checkedTypes.includes(cloneGroup.type)
    );

    // Clear previous content
    cloneList.innerHTML = '';
    cloneDiffContainer.innerHTML = ''; // Also clear the diff view

    // Render filtered clone summaries (reusing logic from renderCloneAnalysis)
    filteredClones.forEach((cloneGroup, index) => {
        const typeClass = `summary-type-${cloneGroup.type}`;
        const summaryDiv = document.createElement('div');
        summaryDiv.className = `bg-blue-50 border border-blue-200 p-3 rounded-lg cursor-pointer hover:bg-blue-100 transition-colors ${typeClass}`;
        
        summaryDiv.innerHTML = `
            <p class="font-bold text-blue-700">Clone Group #${index + 1}: ${cloneGroup.name}</p>
            <p class="text-sm text-gray-600">Fragment Length: ${cloneGroup.fragmentLength} lines. Duplicates: ${cloneGroup.locations.length}</p>
        `;
        summaryDiv.onclick = () => renderCloneFragments(cloneGroup);
        cloneList.appendChild(summaryDiv);
    });

    if (filteredClones.length === 0) {
        cloneList.innerHTML = '<p class="text-gray-500 text-sm p-4">No clone groups match the current filter selection.</p>';
    }

    // Automatically render the first filtered clone group if available
    if (filteredClones.length > 0) {
        renderCloneFragments(filteredClones[0]);
    }
}

/**
 * Renders the side-by-side view for a specific clone group.
 */
async function renderCloneFragments(cloneGroup) {
    cloneDiffContainer.innerHTML = '<div class="text-gray-500 p-4 w-full text-center">Loading code fragments...</div>';

    // We only support side-by-side (2 fragments) for this simple viewer
    const locations = cloneGroup.locations;

    // Fetch all file contents concurrently
    const fileContentsPromises = locations.map(location => getFileContentByPath(location.filePath));
    const fileContents = await Promise.all(fileContentsPromises);
    const cloneType = cloneGroup.type;

    cloneDiffContainer.innerHTML = ''; // Clear loading message

    locations.forEach((location, index) => {
        // Use custom class .clone-fragment-view which is fixed in style.css
        const fragmentContainer = document.createElement('div');
        fragmentContainer.className = 'clone-fragment-view'; 

        // 1. Header
        const header = document.createElement('div');
        header.className = 'clone-header bg-gray-700 text-white p-2 font-mono text-xs truncate rounded-t-lg flex justify-between items-center';
        header.innerHTML = `
            <span>Fragment ${index + 1} | ${location.filePath} (Lines ${location.startLine}-${location.endLine})</span>
            <button class="save-fragment-btn bg-green-500 hover:bg-green-700 text-white text-xs font-semibold py-1 px-2 rounded transition-colors" data-fragment-index="${index}">
                Save
            </button>
        `;
        fragmentContainer.appendChild(header);

        // 2. Code Area (The main content container, flex)
        const codeArea = document.createElement('div');
        // This div is needed to correctly apply the CSS grid layout defined in style.css
        codeArea.className = 'code-area-inner flex-grow flex overflow-hidden'; 

        const fileContent = fileContents[index];
        const fileLines = fileContent.split('\n');

        // Get clone line boundaries
        const startLine = location.startLine;
        const endLine = location.endLine;
        const filePath = location.filePath; // Capture the file path

        const originalFragmentLines = fileLines.slice(location.startLine - 1, location.endLine); 
        const originalFragmentText = originalFragmentLines.join('\n');

        // 4. Content Block (Code using DIV/PRE for highlighting)
        const contentBlock = document.createElement('div');
        contentBlock.className = 'clone-content-display';

        // *** 1. KEY CHANGE: MAKE THE CONTENT EDITABLE ***
        contentBlock.contentEditable = "true";

        // *** 2. Store file metadata for saving ***
        contentBlock.dataset.filepath = filePath;
        contentBlock.dataset.startline = 1; // Content block shows the FULL file, starts at line 1
        contentBlock.dataset.endline = fileLines.length;
        contentBlock.dataset.originalFragmentText = originalFragmentText;

        contentBlock.addEventListener('input', () => {
            // Pass the clone type to the update function
            updateCloneLineNumbers(contentBlock, fragmentLineNumbers, cloneType); 
        });

        const typeClass = `clone-type-${cloneType}`;
        let codeHtml = '';
        for (let i = 0; i < fileLines.length; i++) {
            const lineNumber = i + 1;
            const lineContent = fileLines[i];
            
            const highlightClass = (lineNumber >= startLine && lineNumber <= endLine)
                ? ` ${typeClass}`
                : '';
            
            // Use the custom code-line class
            codeHtml += `<div class="code-line${highlightClass}"><pre>${lineContent}</pre></div>`;
        }

        contentBlock.innerHTML = codeHtml;


        // 3. Line Numbers (Needs to show ALL lines)
        // NOTE: This part is fine, but we will add a listener to update it on input.
        const fragmentLineNumbers = document.createElement('div');
        fragmentLineNumbers.className = 'clone-lines';

        let numbersHtml = '';
        for (let i = 1; i <= fileLines.length; i++) {
            const highlightClass = (i >= startLine && i <= endLine)
                ? ` ${typeClass}`
                : '';
            numbersHtml += `<div class="${highlightClass}">${i}</div>`; 
        }
        fragmentLineNumbers.innerHTML = numbersHtml;

        // Use a scrollable container for the code block
        const scrollWrapper = document.createElement('div');
        scrollWrapper.className = 'code-scroll-wrapper';
        scrollWrapper.appendChild(contentBlock); // Content Block is now inside the wrapper

        // --- Add Listeners to the editable content ---
        scrollWrapper.addEventListener('scroll', (e) => {
            fragmentLineNumbers.scrollTop = e.target.scrollTop;
        });

        contentBlock.addEventListener('input', () => {
            updateCloneLineNumbers(contentBlock, fragmentLineNumbers, cloneType); 
        });

        const saveBtn = header.querySelector('.save-fragment-btn');
        // We need to pass the file path and the element containing the edited code
        saveBtn.addEventListener('click', () => saveCloneFragment(filePath, contentBlock));


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