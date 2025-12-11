module Clones::Token::Type_1_2

import IO;
import String;
import List;
import Set;
import util::Math;
import Map;
import Utility::Hash;
import Utility::Reader;
import Utility::TokenAST;
import lang::java::m3::Core;
import lang::java::m3::AST;
import Conf;
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
/* ============================================================================
 *                          testDuplicateLineCount
 * ----------------------------------------------------------------------------
 *  Ensures that countDuplicates(M3) returns the expected number of duplicated
 *  lines in the test Maven project. This verifies that the final duplicate-line
 *  count, after combining all duplicate blocks, is correct.
 * ============================================================================
 */

list [Clone] findClonesOfType1Or2Token(int cloneType){
    list[Declaration] ast = genASTFromProject(projectRoot);
    bool tokenise = false;
    if (cloneType == 2){
        tokenise = true;
    }
    println("WHAT");
    list[TokenizedLine] lines =  tokeniseAST(ast, tokenise);
    println("WHAT2");
    datetime t0 = now();
    list [Clone] c =  mergeClonePairList(findDuplicates (lines, cloneType));
    list [Clone] reducedClasses = applyTransitivity(c);
    datetime t1 = now();
    println("Create M3 model        <durationToMillis(createDuration(t0, t1))>");
    return reducedClasses;
}
// void TestNoReturn(int cloneType){
//     list[Declaration] ast = genASTFromProject(projectRoot);
//     bool tokenise = false;
//     if (cloneType == 2){
//         tokenise = true;
//     }
//     list[TokenizedLine] lines =  tokeniseAST(ast, tokenise);
//     datetime t0 = now();
//     list [Clone] c =  mergeClonePairList(findDuplicates (lines, cloneType));
//     datetime t1 = now();
//     println("Create M3 model    <durationToMillis(createDuration(t0, t1))>");
//     println("Size               <size(c)>");
//     writeClonesToJson(c);
//     writeLinesOfCodeToJson(getAllFilesFromProjectRoot(projectRoot));
// }
int hashBlock(list[TokenizedLine] lines, int s, int t) {
    // Make sure all lines in the block belong to the same file
    str file = lines[s].sourceLoc.uri;

    list[set[str]] block = [];
    for (k <- [0 .. t]) {
        if (lines[s + k].sourceLoc.uri != file) {
            return -1;  // invalid → this block is ignored
        }
        if (size(lines[s + k].tokens) == 0)
            continue;
        block += lines[s + k].tokens;
    }

    return hash(block);
}

/* ============================================================================
 *                             countDuplicates
 * ----------------------------------------------------------------------------
 *  Counts the number of lines that are part of duplicate blocks in the model.
 *  Delegates the work to findDuplicates after converting the model to lines.
 * ============================================================================
 */
str buildLineKey(TokenizedLine ln) {
    str out = "";
    for (t <- sort(toList(ln.tokens))) {
        out += "\<<t>\>";
    }
     return out;
}

list[Clone] findDuplicates(list[TokenizedLine] lines, int cloneType) {

    lines = removeEmptyTokenLines(lines);
    int t = DUPLICATION_THRESHOLD;

    int n = size(lines);
    if (n < t) return [];

    // 1) Build the same fast hashMap: hash -> starting indices
    map[int, list[int]] hashMap = ();
    for (i <- [0 .. n - t]) {
        int h = hashBlock(lines, i, t);
        if (h == -1) continue;
        hashMap[h] ?= [];
        hashMap[h] += [i];
    }

    list[Clone] clones = [];

    // Precompute deterministic key per line (cheap, done once)
    list[str] lineKey = [ "" | _ <- [0 .. n-1] ];
    for (i <- [0 .. n-1]) {
        lineKey[i] = buildLineKey(lines[i]);
    }

    // 2) For each hash bucket, group by exact block content (resolve collisions)
    for (h <- hashMap) {
        list[int] bucket = hashMap[h];
        if (size(bucket) < 2) continue;

        // Use int hash of block string as primary partition key (smaller map keys)
        // then keep a nested map from blockString -> list[int] to verify equality
        map[int, list[int]] byBlockHash = ();
        map[str, list[int]] exactMap = ();

        for (s <- bucket) {
            // build compact block string from precomputed lineKey entries
            str blockStr = "";
            for (k <- [0 .. t-1]) {
                blockStr += "|" + lineKey[s + k];   // leading '|' avoids accidental merges
            }

            int bh = hash(blockStr);
            byBlockHash[bh] ?= [];
            byBlockHash[bh] += [s];

            // store in exactMap only for the small subset sharing bh
            // (we still need exactMap grouping later)
            // We'll fill exactMap in the next step to avoid string work for unique bhs
        }

        // Now for each bh group build the exactMap (string equality groups)
        for (bh <- byBlockHash) {
            list[int] groupIdx = byBlockHash[bh];
            if (size(groupIdx) < 2) continue;

            for (s <- groupIdx) {
                // build exact blockStr again (only for indices in this small group)
                str blockStr = "";
                for (k <- [0 .. t-1]) {
                    blockStr += "|" + lineKey[s + k];
                }
                exactMap[blockStr] ?= [];
                exactMap[blockStr] += [s];
            }
        }

        // 3) For each exact-equality group, emit only (m-1) pairs:
        for (bk <- exactMap) {
            list[int] group = exactMap[bk];
            int m = size(group);
            if (m < 2) continue;

            int rep = group[0];
            for (idx <- [1 .. m-1]) {
                int other = group[idx];

                Location loc1 = toLocation(lines, rep, t);
                Location loc2 = toLocation(lines, other, t);

                str id = "<h>-<rep>-<other>";
                str name = "TokenClone_<rep>_<other>";

                clones += clone(
                    [loc1, loc2],
                    t,
                    cloneType,
                    id,
                    name
                );
            }
        }
    }

    return clones;
}
