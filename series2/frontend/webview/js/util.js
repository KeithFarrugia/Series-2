// DOM elements
export const openDirBtn = document.getElementById('open-dir-btn');
export const saveBtn = document.getElementById('save-btn');
export const loadClonesBtn = document.getElementById('load-clones-btn');
export const closeClonesBtn = document.getElementById('close-clones-btn');
export const editorContent = document.getElementById('editor-content');
export const lineNumbers = document.getElementById('line-numbers');
export const fileTree = document.getElementById('file-tree');
export const fileStatus = document.getElementById('file-status');
export const currentFileDisplay = document.getElementById('current-file-display');
export const unsavedIndicator = document.getElementById('unsaved-indicator');
export const messageBox = document.getElementById('message-box');

// DOM elements for the clone view
export const standardEditorView = document.getElementById('standard-editor-view');
export const cloneAnalysisView = document.getElementById('clone-analysis-view');
export const cloneList = document.getElementById('clone-list');
export const cloneDiffContainer = document.getElementById('clone-diff-container');

/**
 * Utility function to display non-critical messages.
 */
export function showMessage(text, duration = 3000) {
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
 * Verifies read or read/write permissions for a handle.
 */
export async function verifyPermission(handle, writable) {
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