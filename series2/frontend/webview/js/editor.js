import * as Util from './util.js';
import { currentFileHandle } from './fileExplorer.js';

export let isUnsaved = false;

/**
 * Saves the current editor content back to the file system.
 */
export async function saveFile() {
    if (!currentFileHandle) {
        Util.showMessage("No file is currently open to save.");
        return;
    }

    try {
        if (await Util.verifyPermission(currentFileHandle, true) === false) {
            Util.showMessage("Write permission denied. Cannot save.");
            return;
        }

        const writable = await currentFileHandle.createWritable();
        await writable.write(Util.editorContent.value);
        await writable.close();

        setUnsaved(false);
        Util.showMessage(`File saved successfully: ${currentFileHandle.name}`, 4000);
    } catch (error) {
        console.error('Error saving file:', error);
        Util.showMessage(`Failed to save file: ${error.message}`);
    }
}

/**
 * Updates the content of the line number column based on the textarea content.
 */
export function updateLineNumbers() {
    const newContent = Util.editorContent.value;
    const lineCount = newContent.split('\n').length;
    // Retrieve the original text to search for
    const originalFragmentText = Util.editorContent.dataset.originalFragmentText;
    
    // Find the start index of the original fragment in the new content
    const startIndex = newContent.indexOf(originalFragmentText);

    let newStartLine = -1;
    let newEndLine = -1;

    if (startIndex !== -1) {
        // Calculate the new start line number (1-based) and count the number of newlines occurring bef the match
        newStartLine = (newContent.substring(0, startIndex).match(/\n/g) || []).length + 1;
        
        // Calculate the new end line number
        const fragmentLineCount = (originalFragmentText.match(/\n/g) || []).length + 1;
        newEndLine = newStartLine + fragmentLineCount - 1;
    } 

    let numbersHtml = '';
    for (let i = 1; i <= lineCount; i++) {
        numbersHtml += `<div class=>${i}</div>`;
    }
    Util.lineNumbers.innerHTML = numbersHtml;
}

/**
 * Handles the synchronization of line numbers and content scrolling.
 */
export function syncScroll() {
    Util.lineNumbers.scrollTop = Util.editorContent.scrollTop;
}

/**
 * Sets the unsaved status indicator.
 */
export function setUnsaved(status) {
    isUnsaved = status;
    const name = currentFileHandle?.name || 'Untitled'; 
    if (status) {
        Util.unsavedIndicator.classList.remove('hidden'); 
        document.title = `*Web Code Editor - ${name}`;
    } else {
        Util.unsavedIndicator.classList.add('hidden'); 
        document.title = `Web Code Editor - ${name}`;
    }
}
