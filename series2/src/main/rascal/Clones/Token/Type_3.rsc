module Clones::Token::Type_3

import IO;
import String;
import List;
import Set;
import util::Math;
import Map;
import Utility::Reader;
import Utility::TokenAST;
import lang::java::m3::Core;
import lang::java::m3::AST;
import Conf;
import Utility::CloneMerger;
import Utility::Write;
import Utility::LinesOfCode;
import Utility::CloneMerger;
import DateTime;

int DUPLICATION_THRESHOLD = 6;
int durationToMillis(Duration d) {
  return  d.years   * 1000 * 60 * 60 * 24 * 365
        + d.months  * 1000 * 60 * 60 * 24 * 30
        + d.days    * 1000 * 60 * 60 * 24
        + d.hours   * 1000 * 60 * 60
        + d.minutes * 1000 * 60
        + d.seconds * 1000
        + d.milliseconds;
}
list [Clone] findClonesOfType3Token(){
    list[Declaration] ast = genASTFromProject(projectRoot);
    list[TokenizedLine] lines =  tokeniseAST(ast, true);
    datetime t0 = now();
    list [Clone] c =  applyTransitivity(mergeClonePairList(findType3(lines)));
    datetime t1 = now();
    println("Create M3 model    <durationToMillis(createDuration(t0, t1))>");
    println("Size               <size(c)>");
    return c;
}

bool sameFileBlock(list[TokenizedLine] lines, int s, int t) {
    str file = lines[s].sourceLoc.uri;
    for (k <- [0 .. t-1]) {
        if (lines[s + k].sourceLoc.uri != file) {
            return false;
        }
    }
    return true;
}

void TestNoReturn3(){
    list[Declaration] ast = genASTFromProject(projectRoot);
    list[TokenizedLine] lines =  tokeniseAST(ast, true);
    datetime t0 = now();
    list [Clone] c =  mergeClonePairList(findType3 (lines));
    datetime t1 = now();
    println("Create M3 model    <durationToMillis(createDuration(t0, t1))>");
    println("Size               <size(c)>");
    writeClonesToJson(c);
    writeLinesOfCodeToJson(getAllFilesFromProjectRoot(projectRoot));
}
/* ============================================================================
 * Flatten a block of t lines into a single set of tokens
 * ============================================================================
 */
set[str] flattenBlock(list[TokenizedLine] lines, int s, int t) {
    set[str] group = {};
    for (k <- [0 .. t-1]) {
        group += lines[s + k].tokens;
    }
    return group;
}


/* ============================================================================
 * Jaccard similarity for sets
 * ============================================================================
 */
real jaccard(set[str] A, set[str] B) {
    if (size(A) == 0.0 && size(B) == 0.0) return 1.0;
    real inter = toReal(size(A & B));
    real uni   = toReal(size(A + B));
    return inter / uni;
}

/* ============================================================================
 * Type-3 clone detector with DEBUG OUTPUT
 * ============================================================================
 */

/* ============================================================================
 * Type-3 clone detector with DEBUG OUTPUT
 * ============================================================================
 */
list[Clone] findType3(list[TokenizedLine] lines) {

    lines = removeEmptyTokenLines(lines);

    real SIM_THRESHOLD = 0.70;
    int  t = DUPLICATION_THRESHOLD;
    list[Clone] clones = [];

    int n = size(lines);

    list[set[str]] blocks =
        [ sameFileBlock(lines, i, t) ? flattenBlock(lines, i, t) : {} 
        | i <- [0 .. n - t]
        ];

    // Representatives of current clone groups
    list[int] representatives = [];

    for (i <- [0 .. n - t]) {
        if (!sameFileBlock(lines, i, t)) continue;

        bool matched = false;

        for (rep <- representatives) {

            // NEVER compare a block with itself
            if (i == rep) continue;

            if (!sameFileBlock(lines, rep, t)) continue;

            real sim = jaccard(blocks[i], blocks[rep]);

            if (sim >= SIM_THRESHOLD && sim < 1.0) {

                // Create the minimal pair (rep, i)
                Location loc1 = toLocation(lines, rep, t);
                Location loc2 = toLocation(lines, i, t);

                str id   = "T3_<rep>_<i>";
                str name = "Type3Clone_<rep>_<i>";

                clones += clone([loc1, loc2], t, 3, id, name);

                matched = true;
                break;   // IMPORTANT: stops full cross-product
            }
        }

        if (!matched) {
            // Only add as a representative AFTER we check old ones
            representatives += i;
        }
    }

    return clones;
}