import * as Util from './util.js';
import { directoryHandle, getFileContentByPath } from './fileExplorer.js';
import { verifyPermission } from './util.js';

export let currentClonesData = null;

/**
 * Switches between the standard editor view and the clone analysis view.
 * @param {boolean} showCloneView - True to show clone view, false to show editor.
 */
export function toggleView(showCloneView) {
    if (showCloneView) {
        Util.standardEditorView.classList.add('hidden');
        Util.cloneAnalysisView.classList.remove('hidden');
        Util.cloneAnalysisView.classList.add('flex'); // Ensure it uses flex layout when visible
        Util.loadClonesBtn.classList.add('hidden');
    } else {
        Util.standardEditorView.classList.remove('hidden');
        Util.cloneAnalysisView.classList.add('hidden');
        Util.loadClonesBtn.classList.remove('hidden');
    }
}

/**
 * Loads the clone analysis JSON data. It prioritizes loading the file from the
 * user's opened project directory via the File System Access API, otherwise
 * it falls back to fetching a static file via HTTP (for testing).
 */
export async function loadSampleJson() {
    if (!directoryHandle) {
        Util.showMessage("Please open the project directory first using the 'Open Project Directory' button.", 6000);
        return;
    }
    Util.showMessage("Loading clone analysis data...");
    try {
        const CLONE_FILE_NAME = '../clones.json';
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
            try {
                const text = await response.text();
                responseData = JSON.parse(text);
            } catch (parseError) {
                // If parsing fails, throw a clear error that the outer catch block can handle
                throw new Error(`Failed to parse clone JSON data. File is likely malformed. Details: ${parseError.message}`);
            }
        }

        currentClonesData = responseData;
        
        renderCloneAnalysis();
        toggleView(true); // Switch to the clone view
        Util.showMessage(`Successfully loaded ${currentClonesData.clones.length} clone group(s). Source: ${source}`);

    } catch (error) {
        console.error('Error loading clone data:', error);
        Util.showMessage(`Failed to load clone analysis: ${error.message}`, 8000);
    }
}

/**
 * Renders the full clone analysis view with summaries and side-by-side diffs.
 */
export function renderCloneAnalysis() {
    if (!currentClonesData) return;

    applyCloneFilter();

    // Clear previous content
    Util.cloneList.innerHTML = '';
    Util.cloneDiffContainer.innerHTML = '';

    // Render clone summaries
    currentClonesData.clones.forEach((cloneGroup, index) => {
        // Determine the CSS class based on the type number (1, 2, or 3)
        const typeClass = `summary-type-${cloneGroup.cloneType}`;
        
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
        Util.cloneList.appendChild(summaryDiv);
    });

    // Automatically render the first clone group
    if (currentClonesData.clones.length > 0) {
        renderCloneFragments(currentClonesData.clones[0]);
    }
}

export function updateCloneLineNumbers(contentElement, lineNumbersElement, cloneType) {
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
export function getEditableContentText(contentElement) {
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
export async function saveCloneFragment(filePath, contentElement) {
    if (!directoryHandle) {
        Util.showMessage("Error: No project directory is open.", 5000);
        return;
    }
    
    // 1. Get the current edited content
    const newContent = getEditableContentText(contentElement);
    
    // 2. Get the file handle via path traversal (using the robust export function you just added)
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
        Util.showMessage(`Failed to locate file ${filePath} for saving.`, 5000);
        return;
    }

    // 3. Perform save operation
    try {
        if (await verifyPermission(fileHandle, true) === false) {
            Util.showMessage("Write permission denied. Cannot save file.", 5000);
            return;
        }

        const writable = await fileHandle.createWritable();
        await writable.write(newContent);
        await writable.close();

        Util.showMessage(`File saved successfully: ${filePath}`, 4000);

    } catch (error) {
        console.error('Error saving file:', error);
        Util.showMessage(`Failed to save file: ${error.message}`, 8000);
    }
}

export function applyCloneFilter() {
    if (!currentClonesData || !currentClonesData.clones) return;
    try {
        // Get the status of the checkboxes
        const checkedTypes = Array.from(document.querySelectorAll('#clone-filter-controls input[type="checkbox"]:checked'))
            .map(input => parseInt(input.value)); // Get the checked values as numbers

        // Filter the original clone data
        const filteredClones = currentClonesData.clones.filter(cloneGroup => 
            checkedTypes.includes(cloneGroup.cloneType)
        );

        // Clear previous content
        Util.cloneList.innerHTML = '';
        Util.cloneDiffContainer.innerHTML = ''; // Also clear the diff view

        // Render filtered clone summaries (reusing logic from renderCloneAnalysis)
        filteredClones.forEach((cloneGroup, index) => {
            const typeClass = `summary-type-${cloneGroup.cloneType}`;
            const summaryDiv = document.createElement('div');
            summaryDiv.className = `bg-blue-50 border border-blue-200 p-3 rounded-lg cursor-pointer hover:bg-blue-100 transition-colors ${typeClass}`;
            
            summaryDiv.className = `**bg-blue-900** border **border-blue-700** p-3 rounded-lg cursor-pointer **hover:bg-blue-800** transition-colors ${typeClass}`;
            summaryDiv.innerHTML = `
                <p class="font-bold **text-blue-300**">Clone Group #${index + 1}: ${cloneGroup.name}</p>
                <p class="text-sm **text-gray-400**">Fragment Length: ${cloneGroup.fragmentLength} lines. Duplicates: ${cloneGroup.locations.length}</p>
            `;
            summaryDiv.onclick = () => renderCloneFragments(cloneGroup);
            Util.cloneList.appendChild(summaryDiv);
        });

        if (filteredClones.length === 0) {
            Util.cloneList.innerHTML = '<p class="text-gray-500 text-sm p-4">No clone groups match the current filter selection.</p>';
        }

        // Automatically render the first filtered clone group if available
        if (filteredClones.length > 0) {
            renderCloneFragments(filteredClones[0]);
        }
    } catch (error) {
        console.error("ERROR in applyCloneFilter:", error);
        Util.showMessage(`Filter error: ${error.message}`, 8000);
    }
}

/**
 * Renders the side-by-side view for a specific clone group.
 */
export async function renderCloneFragments(cloneGroup) {
    Util.cloneDiffContainer.innerHTML = '<div class="text-gray-500 p-4 w-full text-center">Loading code fragments...</div>';

    // We only support side-by-side (2 fragments) for this simple viewer
    const locations = cloneGroup.locations;

    // Fetch all file contents concurrently
    const fileContentsPromises = locations.map(location => getFileContentByPath(location.filePath));
    const fileContents = await Promise.all(fileContentsPromises);
    const cloneType = cloneGroup.cloneType;

    Util.cloneDiffContainer.innerHTML = ''; // Clear loading message
    locations.forEach((location, index) => {
        console.log(`Rendering Fragment ${index + 1} from ${location.filePath} (Lines ${location.startLine}-${location.endLine})`);
        try {
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

            if (fileContent.startsWith('// Error:')) {
                console.warn(`Skipping fragment ${index + 1} due to file access error: ${fileContent}`);
                
                const errorDiv = document.createElement('div');
                errorDiv.className = 'clone-fragment-view p-3 bg-red-100 border border-red-400 text-red-700 m-2 rounded';
                errorDiv.innerHTML = `
                    <p class="font-bold">Fragment ${index + 1} Skipped</p>
                    <p class="text-sm">${location.filePath} (Lines ${location.startLine}-${location.endLine})</p>
                    <p class="text-xs mt-1">Error fetching content. Check console for details.</p>
                `;
                Util.cloneDiffContainer.appendChild(errorDiv);
                return; // Skip this fragment
            }
            
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

            Util.cloneDiffContainer.appendChild(fragmentContainer);
        } catch (error) {
            // Log a specific error for the failed fragment instead of crashing the whole process
            console.error(`ERROR: Failed to render Fragment ${index + 1} (${location.filePath}, lines ${location.startLine}-${location.endLine}).`, error);
            
            const errorDiv = document.createElement('div');
            errorDiv.className = 'p-3 bg-red-100 border border-red-400 text-red-700 m-2 rounded';
            errorDiv.innerHTML = `Failed to load Fragment ${index + 1}. Check console for details.`;
            Util.cloneDiffContainer.appendChild(errorDiv);
        }
    });
}