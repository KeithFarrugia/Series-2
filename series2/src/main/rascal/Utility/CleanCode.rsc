module Utility::CleanCode

import IO;
import List;
import String;
import Set;

/* ============================================================================
 *                              countLOC
 * ----------------------------------------------------------------------------
 *  Count the number of non-empty, non-comment lines in a given source string.
 *  This function first cleans the source code using cleanSource, then counts
 *  lines that contain actual code (ignores empty lines).
 * ============================================================================
 */
public str cleanSource(str sourcestr) {
    
    // 1. Normalise all non-standard whitespace characters (like non-breaking space) 
    // to a standard space for consistency.
    // This is a safety step against unprintable characters.
    str normalizedWhitespace = replaceAll(sourcestr, "[\\p{Z}\\s]", "\n");

    // 2. Remove Multi-line comments: /* ... */
    str noMultiLineComments = visit(normalizedWhitespace) {
        case /\/\*[\s\S]*?\*\// => "\n"
    };

    // 3. Remove Single-line comments: // ...
    str noAllComments = visit(noMultiLineComments) {
        case /\/\/[^\n]*/ => "\n" 
    };

    // 4. Collapse multiple consecutive blank lines into a single blank line
    str finalCleanstr = visit(noAllComments) {
        case /^\n[ \t\n]*\n/ => "\n"  
    };

    return finalCleanstr;
}
