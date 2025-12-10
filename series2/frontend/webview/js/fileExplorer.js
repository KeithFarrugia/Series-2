import * as Util from './util.js';
import * as Editor from './editor.js';
import { verifyPermission } from './util.js';

export let directoryHandle = null;
export let currentFileHandle = null;

/**
 * Recursively reads and builds the file tree structure.
 */
async function buildFileTree(dirHandle, path = '') {
    const ul = document.createElement('ul');
    ul.className = 'ml-3 space-y-1';

    for await (const entry of dirHandle.values()) {
        const li = document.createElement('li');
        li.className = 'cursor-pointer hover:bg-gray-700 p-1 rounded transition-colors';

        if (entry.kind === 'file') {
            const filename = entry.name;
            li.innerHTML = `<span class="text-sky-400">📄 ${filename}</span>`;
            li.dataset.filename = filename;
            li.dataset.path = path;
            li.onclick = () => openFile(entry); 
        } else if (entry.kind === 'directory') {
            const dirName = entry.name;
            const newPath = path ? `${path}/${dirName}` : dirName;
            
            const toggler = document.createElement('span');
            toggler.className = '**text-gray-200** font-semibold inline-block w-full';
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
    if (Editor.isUnsaved) {
        Util.showMessage("You have unsaved changes. Please save or discard manually before opening a new file.", 5000);
        return;
    }

    try {
        if (await verifyPermission(fileHandle, false) === false) {
            Util.showMessage("Read permission denied for this file.");
            return;
        }

        const file = await fileHandle.getFile();
        const contents = await file.text();

        currentFileHandle = fileHandle;
        Util.editorContent.value = contents;
        Util.currentFileDisplay.textContent = fileHandle.name;
        Util.editorContent.disabled = false;
        Util.saveBtn.disabled = false;
        Editor.updateLineNumbers();
        Editor.setUnsaved(false);
        Util.showMessage(`File opened: ${fileHandle.name}`);

    } catch (error) {
        console.error('Error opening file:', error);
        Util.showMessage(`Could not open file: ${fileHandle.name}. Error: ${error.message}`);
        currentFileHandle = null;
        Util.editorContent.value = '';
        Util.currentFileDisplay.textContent = '-- No file open --';
    }
}

/**
 * Prompts the user to select a directory and builds the file tree.
 */
export async function openDirectory() {
    if ('showDirectoryPicker' in window) {
        try {
            directoryHandle = await window.showDirectoryPicker();
            Util.fileStatus.textContent = `Directory: ${directoryHandle.name}`;
            Util.fileTree.innerHTML = '<p class="text-gray-500">Loading directory structure...</p>';

            const tree = await buildFileTree(directoryHandle);
            Util.fileTree.innerHTML = '';
            Util.fileTree.appendChild(tree);

            Util.showMessage(`Successfully opened directory: ${directoryHandle.name}`);

        } catch (error) {
            console.error('Directory access denied or error:', error);
            if (error.name === 'AbortError') {
                 Util.showMessage(`Directory selection cancelled.`);
            } else {
                 Util.showMessage(`Access denied or error: ${error.message}`);
            }
        }
    } else {
        Util.showMessage("Your browser does not support the File System Access API. Try Chrome, Edge, or Opera.", 6000);
    }
}

/**
 * Reads the content of a file within the opened directory based on its path using FSA.
 * This function iterates through the path segments, which is the most robust way
 * to handle deep paths with the File System Access API.
 * * @param {string} filePath - The file path (e.g., 'src/main/java/org/sigmetrics/Duplication.java')
 * @returns {Promise<string>} The content of the file or an error message.
 */
export async function getFileContentByPath(filePath) {
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