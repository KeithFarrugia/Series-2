module Clones::Type1

import IO;
import String;
import List;
import Set;
import util::Math;
import Map;
import Utility::Hash;
import Utility::Reader;
import lang::java::m3::Core;
import lang::java::m3::AST;

int DUPLICATION_THRESHOLD = 6;
/* ============================================================================
 *                             countDuplicates
 * ----------------------------------------------------------------------------
 *  Counts the number of lines that are part of duplicate blocks in the model.
 *  Delegates the work to findDuplicates after converting the model to lines.
 * ============================================================================
 */
int countDuplicates(M3 model) {
    list[str] lines = modelToLines(model);
    return findDuplicates(lines);
}

int findDuplicates(list[str] lines) {
    int t = DUPLICATION_THRESHOLD;
    map[int, list[int]] hashMap = ();      // hash -> starting indices
    set[int] duplicated = {};

    int n = size(lines);
    if (n < t) return 0;

    // 1. Build a hash for every t-line block
    for (i <- [0 .. n - t]) {
        if (lines[i] == "}") continue;

        int h = hashBlock(lines, i, t);

        if (h in hashMap)
            hashMap[h] += [i];
        else
            hashMap[h] = [i];
    }
    
    // 2. For every hash that occurs more than once, mark duplicates
    for (h <- hashMap) {
        list[int] starts = hashMap[h];
        if (size(starts) < 2) continue;

        // Print each duplicate block
        for (s <- starts) {
            println("Duplicate block starting at line <s>:");
            for (k <- [0 .. t]) {
                duplicated += {s + k};
                println("  <lines[s + k]>");   // print each line
            }
            println("");  // blank line between blocks
        }
    }
    // for (i <- [0 .. size(lines)-1]) {
    //     println("Line <i>: <lines[i]>");
    // }
    // for (h <- sort([k | k <- hashMap])) { // sort keys for readability
    //     list[int] indices = hashMap[h];
    //     println("Hash <h>  Starting lines: <indices>");
    // }
    // println("SIZE OF HASH MAP: <size(hashMap)>");

    return size(duplicated);
}

