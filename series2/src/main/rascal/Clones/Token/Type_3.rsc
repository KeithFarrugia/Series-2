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
    writeLinesOfCodeToJson(getAllFilesFromProjectRoot());
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

real fastJaccard(set[str] A, set[str] B) {
    int sizeA = size(A);
    int sizeB = size(B);
    if (sizeA == 0 && sizeB == 0) return 1.0;
    int inter = size(A & B);
    int uni = sizeA + sizeB - inter;
    if (uni == 0) return 0.0;
    return toReal(inter) / toReal(uni);
}

// Helper: early prune by size
bool canReachThreshold(int sizeA, int sizeB, real threshold) {
    int maxInter = sizeA < sizeB ? sizeA : sizeB;
    if (sizeA + sizeB - maxInter == 0) return false;
    real maxJ = toReal(maxInter) / toReal(sizeA + sizeB - maxInter);
    return maxJ >= threshold;
}
list[Clone] findType3(list[TokenizedLine] lines) {

    lines = removeEmptyTokenLines(lines);

    real SIM_THRESHOLD = 0.70;
    int  t = DUPLICATION_THRESHOLD;
    list[Clone] clones = [];

    int n = size(lines);

    // --- 1) build token id mapping and blocks as set<int> ---
    map[str,int] tokenId = ();
    int nextId = 0;

    list[set[int]] blocks = [];
    list[int] blockSize = [];

    for (i <- [0 .. n - t]) {
        if (!sameFileBlock(lines, i, t)) {
            blocks += ({});            // keep indices aligned
            blockSize += 0;
            continue;
        }
        set[int] s = {};
        for (k <- [0 .. t-1]) {
            for (tok <- lines[i + k].tokens) {
                if (!(tok in tokenId)) {
                    tokenId[tok] = nextId;
                    nextId += 1;
                }
                s += { tokenId[tok] };
            }
        }
        blocks += s;
        blockSize += size(s);
    }

    // --- 2) representatives grouped by file and token->rep inverted index ---
    map[str, list[int]] repsByFile = ();
    map[int, set[int]] tokenToReps = ();

    // helpers
    int requiredIntersection(int aSize, int bSize, real thr) {
        // derived from inter >= thr * (a + b - inter)
        // => inter*(1+thr) >= thr*(a+b) => inter >= thr*(a+b)/(1+thr)
        return toInt(ceil(thr * (aSize + bSize) / (1.0 + thr)));
    }

    // --- 3) main loop ---
    for (i <- [0 .. n - t]) {
        if (!sameFileBlock(lines, i, t)) continue;

        str file = lines[i].sourceLoc.uri;
        set[int] Ai = blocks[i];
        int sizeAi = blockSize[i];

        bool matched = false;

        // get candidate reps: union of tokenToReps for tokens in Ai
        set[int] candidateReps = {};
        for (tok <- Ai) {
            if (tok in tokenToReps) {
                candidateReps += tokenToReps[tok];
            }
        }

        // if no candidate from token overlap, fall back to comparing all reps in file
        list[int] repsList = 
            (size(candidateReps) > 0) 
              ? toList(candidateReps) 
              : (file in repsByFile ? repsByFile[file] : []);

        // iterate candidates (order doesn't matter), but ensure we never compare i==rep
        for (rep <- repsList) {
            if (matched) break;
            if (rep == i) continue;

            // same file guard (should hold) - cheap check
            if (lines[rep].sourceLoc.uri != file) continue;

            int sizeBi = blockSize[rep];

            // cheap numeric upper bound: if min/max < SIM_THRESHOLD skip
            int mn = sizeAi < sizeBi ? sizeAi : sizeBi;
            int mx = sizeAi < sizeBi ? sizeBi : sizeAi;
            if (mn == 0 && sizeAi == 0 && sizeBi == 0) {
                // special-case: both empty -> jaccard 1.0 (but we avoid self-pairs)
                // We'll treat this as a candidate - compute full jaccard below
                ;
            } else if (toReal(mn) / toReal(mx) < SIM_THRESHOLD) {
                continue;
            }

            // tighter required intersection test
            int req = requiredIntersection(sizeAi, sizeBi, SIM_THRESHOLD);
            if (mn < req) continue;

            // compute full intersection and jaccard
            set[int] inter = Ai & blocks[rep];
            int interSize = size(inter);
            int uniSize = sizeAi + sizeBi - interSize;
            real sim = (uniSize == 0) ? 1.0 : toReal(interSize) / toReal(uniSize);

            if (sim >= SIM_THRESHOLD && sim < 1.0) {
                Location loc1 = toLocation(lines, rep, t);
                Location loc2 = toLocation(lines, i, t);

                str id   = "T3_<rep>_<i>";
                str name = "Type3Clone_<rep>_<i>";

                clones += clone([loc1, loc2], t, 3, id, name);

                matched = true;
                break; // stop after first matching representative
            }
        }

        if (!matched) {
            // add i as new representative for its file
            if (file in repsByFile) {
                repsByFile[file] = repsByFile[file] + [i];
            } else {
                repsByFile[file] = [i];
            }
            // update inverted index for tokens in this new representative
            for (tok <- Ai) {
                if (tok in tokenToReps) {
                    tokenToReps[tok] += { i };
                } else {
                    tokenToReps[tok] = { i };
                }
            }
        }
    }

    return clones;
}