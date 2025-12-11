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
import Utility::Hash;
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

    return applyTransitivity(mergeClonePairList(findType3(lines)));
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

// Coarse MinHash-like signature: small buckets, robust to noise
// Defensive fastHash: never sums an empty list and logs unexpected cases.
int fastHash(set[str] toks) {
    // empty token set -> bucket 0
    if (size(toks) == 0) {
        return 0;
    }

    // build list of token-hashes; filter out any unexpected nulls (defensive)
    list[int] hs = [];
    for (t <- toks) {
        // defensive: ensure t is not null/empty string
        if (t == "" || t == null) {
            // skip weird tokens
            continue;
        }
        // abs(hash(...)) should be an int; keep it
        hs += abs(hash(t));
    }

    // if nothing remained, put into special bucket 0
    if (size(hs) == 0) {
        println("fastHash: WARNING - all token hashes filtered out for a block bucket 0");
        return 0;
    }

    hs = sort(hs);

    // choose up to k smallest hashes (k at most 5)
    int k = size(hs) < 5 ? size(hs) : 5;
    if (k == 0) {
        // defensive fallback
        println("fastHash: WARNING - k == 0 after building hs bucket 0");
        return 0;
    }

    // build prefix safely (no risk of sum([]) now)
    list[int] prefix = hs[0 .. k - 1];
    if (size(prefix) == 0) {
        println("fastHash: WARNING - empty prefix despite k 0 bucket 0");
        return 0;
    }

    int acc = 0;
    for (v <- prefix) acc += v;

    return acc % 5000;
}



/* ============================================================================
 * Type-3 clone detector with DEBUG OUTPUT
 * ============================================================================
 */
list[Clone] findType3(list[TokenizedLine] lines) {
    list[Clone] result = [];
    lines = removeEmptyTokenLines(lines);
    int t = DUPLICATION_THRESHOLD;
    real SIM_THRESHOLD = 0.70;

    int n = size(lines);
    println("Precompute");

    // Precompute file ID and flattened blocks
    list[str] fileId = [ l.sourceLoc.uri | l <- lines ];
    list[set[str]] blocks = [];
    for (i <- [0 .. n - t]) { 
        blocks += flattenBlock(lines, i, t); 
    }

    println("Computing buckets");
    map[int, list[int]] buckets = ();

    for (i <- index(blocks)) {
        if (i % 10000 == 0) println("  bucket progress index: <i>");

        if (size(blocks[i]) == 0) {
            // optionally store empty blocks:
            // buckets[0] = (buckets[0] ? []) + [i];
            continue;
        }

        int h = fastHash(blocks[i]);

        if (h == 0 && size(blocks[i]) > 0) {
            println("fastHash returned 0 for non-empty block index <i> tokens: <blocks[i]>");
        }

        list[int] current = buckets[h] ? [];
        current += i;
        buckets[h] = current;
    }


    // Compare only inside buckets
    for (h <- domain(buckets)) {
        list[int] bucket = buckets[h];

        // Skip tiny buckets
        if (size(bucket) < 2) continue;

        for (i <- bucket) {
            for (j <- bucket) {
                if (i >= j) continue;
                if (fileId[i] != fileId[j]) continue;

                real sim = jaccard(blocks[i], blocks[j]);

                if (sim >= SIM_THRESHOLD && sim < 1.0) {
                    result += makeClone(i, j, t, lines);
                }
            }
        }
    }

    return result;
}

Clone makeClone(int i, int j, int t, list[TokenizedLine] lines) {
    Location loc1 = toLocation(lines, i, t);
    Location loc2 = toLocation(lines, j, t);
    str id = "T3_<i>_<j>";
    str name = "Type3Clone_<i>_<j>";
    return clone([loc1, loc2], t, 3, id, name);
}
