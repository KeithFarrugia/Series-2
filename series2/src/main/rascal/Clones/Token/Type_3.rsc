module Clones::Token::Type_3


import IO;
import String;
import List;
import Set;
import util::Math;
import Map;
import DateTime;

import lang::java::m3::Core;
import lang::java::m3::AST;

import Conf;
import Utility::Hash;
import Utility::Reader;
import Utility::TokenAST;
import Utility::CloneMerger;
import Utility::Timings;

/* ============================================================================
 *                        findClonesOfType3Token
 * ----------------------------------------------------------------------------
 *  Entry point for Type-3 token-based clone detection. Generates the AST,
 *  tokenises the source, detects approximate duplicates, and merges clone
 *  pairs into clone classes.
 * ============================================================================
 */
list [Clone] findClonesOfType3Token(){
    list[Declaration]   ast     = genASTFromProject(projectRoot);
    list[TokenizedLine] lines   =  tokeniseAST(ast, true);
    
    datetime     t0 = now();
    list [Clone] c  = mergeClonePairList(findType3(lines));
    datetime     t1 = now();

    println("Clone detection time  (Token Type 3) <calcTime(t0, t1)>ms");
    return c;
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
 *                              fastJaccard
 * ----------------------------------------------------------------------------
 *  Computes the Jaccard similarity between two token sets with defensive
 *  handling of empty inputs.
 * ============================================================================
 */
real fastJaccard(set[str] A, set[str] B) {
    int sizeA = size(A);
    int sizeB = size(B);

    if (sizeA == 0 && sizeB == 0)
        return 1.0;

    int inter = size(A & B);
    int uni   = sizeA + sizeB - inter;

    if (uni == 0)
        return 0.0;

    return toReal(inter) / toReal(uni);
}

/* ============================================================================
 *                               fastHash
 * ----------------------------------------------------------------------------
 *  Computes a coarse MinHash-like signature for a token set. Designed to be
 *  robust to noise and safe for empty or malformed inputs.
 * ============================================================================
 */
int fastHash(set[str] toks) {

    if (size(toks) == 0)
        return 0;

    list[int] hs = [];

    for (t <- toks) {
        if (t == "") continue;
        hs += abs(hash(t));
    }

    if (size(hs) == 0)
        return 0;

    hs = sort(hs);

    int         k       = size(hs) < 5 ? size(hs) : 5;
    list[int]   prefix  = hs[0 .. k - 1];

    int acc = 0;
    for (v <- prefix)
        acc += v;

    return acc % 5000;
}




/* ============================================================================
 *                                findType3
 * ----------------------------------------------------------------------------
 *  Core Type-3 clone detection algorithm. Uses coarse hashing for candidate
 *  selection followed by Jaccard similarity for approximate matching.
 * ============================================================================
 */
list[Clone] findType3(list[TokenizedLine] lines) {

                lines           = removeEmptyTokenLines(lines);
    int         t               = DUPLICATION_THRESHOLD;
    int         n               = size(lines);
    list[Clone] result          = [];


    /* --------------------------------------------------------------------
     * Step 1: Precompute flattened token blocks
     * -------------------------------------------------------------------- */
    list[set[str]] blocks = [];
    for (i <- [0 .. n - t]) {
        blocks += flattenBlock(lines, i, t);
    }

    /* --------------------------------------------------------------------
     * Step 2: Bucket blocks using coarse hash
     * -------------------------------------------------------------------- */
    map[int, list[int]] buckets = ();

    for (i <- index(blocks)) {
        int h = fastHash(blocks[i]);

        buckets[h] ?= [];
        buckets[h] += [i];
    }


    /* --------------------------------------------------------------------
     * Step 3: Pairwise comparison inside buckets
     * -------------------------------------------------------------------- */
    for (h <- domain(buckets)) {
        list[int] bucket = buckets[h];
        if (size(bucket) < 2) { continue; }


        for (i <- bucket) {
            for (j <- bucket) {
                if (i >= j)         continue;
                if (abs(i - j) < t) continue;

                real sim = fastJaccard(blocks[i], blocks[j]);

                if (sim >= SIM_THRESHOLD && sim < 1.0) {
                    
                    Location loc1 = toLocation(lines, i, t);
                    Location loc2 = toLocation(lines, j, t);

                    result += clone(
                        [loc1, loc2],                   // 2 Locations (Block A and B)
                        t,                              // Block size
                        3,                              // Clone Type
                        "T3-<i>-<j>",                   // ID
                        "Type3Clone_<i>_<j>"            // Clone Class Name
                    );
                }
            }
        }
    }

    return result;
}

