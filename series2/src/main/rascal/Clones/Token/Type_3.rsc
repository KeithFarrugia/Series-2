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

    return mergeClonePairList(findType3(lines));
}

bool sameFileBlock(list[TokenizedLine] lines, int s, int t) {
    str file = lines[s].sourceLoc.uri;
    for (k <- [0 .. t]) {
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
    for (k <- [0 .. t]) {
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
list[Clone] findType3(list[TokenizedLine] lines) {
    lines = removeEmptyTokenLines(lines);

    real SIM_THRESHOLD = 0.70;
    int  t = DUPLICATION_THRESHOLD;
    list[Clone] clones = [];

    int n = size(lines);
    if (n < t) return [];

    // 1) Precompute blocks (same as before) - blocks[i] is {} if not sameFileBlock
    list[set[str]] blocks =
      [ sameFileBlock(lines, i, t) ? flattenBlock(lines, i, t) : {}
      | i <- [0 .. n - t]
      ];

    // 2) Group starting indices by file (so we only compare inside same file)
    map[str, list[int]] fileStarts = ();
    for (i <- [0 .. n - t]) {
        if (!sameFileBlock(lines, i, t)) continue;
        str file = lines[i].sourceLoc.uri;
        fileStarts[file] ?= [];
        fileStarts[file] += [i];
    }

    // 3) Process each file independently
    for (file <- fileStarts) {
        list[int] starts = fileStarts[file];

        // Greedy-assignment set: indices already assigned as non-representative
        set[int] assigned = {};

        // Iterate starts in increasing order; treat earliest unassigned as rep
        for (idx <- [0 .. size(starts)-1]) {
            int i = starts[idx];
            if (i in assigned) continue;        // already clustered to a previous rep

            // skip empty blocks (should not occur because of sameFileBlock test,
            // but we guard anyway)
            if (size(blocks[i]) == 0) continue;

            // representative for this cluster
            int rep = i;

            // scan later starts only (j > i)
            for (jidx <- [idx+1 .. size(starts)-1]) {
                int j = starts[jidx];

                if (j in assigned) continue;   // don't re-check blocks already assigned

                // cheap size-ratio pruning:
                // only possible to have Jaccard >= S if size ratio is within [S, 1/S]
                int a = size(blocks[rep]);
                int b = size(blocks[j]);
                if (a == 0 || b == 0) continue;

                // use reals for the ratio check
                real ra = toReal(a);
                real rb = toReal(b);
                real S  = SIM_THRESHOLD;

                if (rb < S * ra) continue;
                if (rb > ra / S) continue;

                // now do the actual Jaccard (costly) only for promising candidates
                real sim = jaccard(blocks[rep], blocks[j]);

                // require >= threshold and strictly < 1.0 (exclude exact matches)
                if (sim >= SIM_THRESHOLD && sim < 1.0) {
                    Location loc1 = toLocation(lines, rep, t);
                    Location loc2 = toLocation(lines, j, t);

                    str id = "T3_<rep>_<j>";
                    str name = "Type3Clone_<rep>_<j>";

                    clones += clone(
                        [loc1, loc2],
                        t,
                        3,
                        id,
                        name
                    );

                    // assign j to this rep so j won't be paired again as a member
                    assigned += j;
                }
            }
        }
    }

    return clones;
}
