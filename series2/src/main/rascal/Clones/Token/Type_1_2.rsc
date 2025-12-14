module Clones::Token::Type_1_2

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
 *                     findClonesOfType1Or2Token
 * ----------------------------------------------------------------------------
 *  Entry point for Type-1 and Type-2 token-based clone detection. Generates
 *  the AST, tokenises lines as required, detects duplicate blocks, merges
 *  clone pairs, and applies transitive reduction.
 * ============================================================================
 */
list[Clone] findClonesOfType1Or2Token(int cloneType) {
    list[Declaration]   ast         = genASTFromProject(projectRoot);
    bool                tokenise    = cloneType == 2;
    list[TokenizedLine] lines       = tokeniseAST(ast, tokenise);

    datetime t0 = now();
    list[Clone] rawClones = mergeClonePairList(findDuplicates(lines, cloneType));
    list[Clone] reduced   = applyTransitivity(rawClones);
    datetime t1 = now();

    println("Clone detection time  (Token Type <cloneType>) <calcTime(t0, t1)>");

    return reduced;
}

/* ============================================================================
 *                               hashBlock
 * ----------------------------------------------------------------------------
 *  Computes a hash for a block of tokenised lines starting at index s with
 *  length t, ensuring all lines belong to the same source file.
 * ============================================================================
 */
int hashBlock(list[TokenizedLine] lines, int s, int t) {
    str file = lines[s].sourceLoc.uri;
    list[set[str]] block = [];

    for (k <- [0 .. t]) {
        /* -------------------------------------------------------------------- 
         * Check if all lines are containined in same file 
         * -------------------------------------------------------------------- */
        if (lines[s + k].sourceLoc.uri != file){
            return -1;
        }

        /* -------------------------------------------------------------------- 
         * Concatinate lines
         * -------------------------------------------------------------------- */
        if (size(lines[s + k].tokens) > 0){
            block += lines[s + k].tokens;
        }
    }

    return hash(block);
}

/* ============================================================================
 *                               buildLineKey
 * ----------------------------------------------------------------------------
 *  Builds a deterministic string representation of a tokenised line by
 *  sorting and concatenating its tokens.
 * ============================================================================
 */
str buildLineKey(TokenizedLine ln) {
    str out = "";

    for (t <- sort(toList(ln.tokens))){
        out += "\<<t>\>";
    }

    return out;
}

/* ============================================================================
 *                              findDuplicates
 * ----------------------------------------------------------------------------
 *  Detects Type-1 or Type-2 token-based clone blocks using hashing and exact
 *  matching. Hash collisions are resolved through secondary grouping.
 * ============================================================================
 */
list[Clone] findDuplicates(list[TokenizedLine] lines, int cloneType) {

                lines   = removeEmptyTokenLines(lines);
    int         t       = DUPLICATION_THRESHOLD;
    int         n       = size(lines);
    list[Clone] clones  = [];

    if (n < t){ return []; }


    /* -------------------------------------------------------------------- 
     *  Step 1: Build hash buckets of candidate blocks
     * -------------------------------------------------------------------- */
    map[int, list[int]] hashMap = ();

    for (i <- [0 .. n - t]) {
        int h = hashBlock(lines, i, t);
        if (h == -1) continue;

        hashMap[h] ?= [];
        hashMap[h] += [i];
    }

    /* --------------------------------------------------------------------
     * Step 2: Precompute per-line deterministic keys
     * -------------------------------------------------------------------- */
    list[str] lineKey = [ "" | _ <- [0 .. n] ];
    for (i <- [0 .. n]) {
        lineKey[i] = buildLineKey(lines[i]);
    }

     /* --------------------------------------------------------------------
     * Step 3: Resolve hash collisions and emit clone pairs
     * -------------------------------------------------------------------- */
    for (h <- hashMap) {
        list[int] bucket = hashMap[h];
        if (size(bucket) < 2) continue;

        /* -----------------------------------------------
         * These are the two smaller hash maps we use to
         * resolve collisions (optimisation) */
        
        map[int, list[int]] byBlockHash = ();
        map[str, list[int]] exactMap    = ();

    
        /* --------------------------------------------------------------------
         * Step 3.1: First Collision reduction
         * -------------------------------------------------------------------- */
        for (s <- bucket) {
            str blockStr = "";
            for (k <- [0 .. t]) {
                blockStr += "|" + lineKey[s + k];
            }

            int bh = hash(blockStr);
            byBlockHash[bh] ?= [];
            byBlockHash[bh] += [s];
        }

        /* --------------------------------------------------------------------
         * Step 3.2: Second Collision reduction
         * -------------------------------------------------------------------- */
        for (bh <- byBlockHash) {
            list[int] groupIdx = byBlockHash[bh];
            if (size(groupIdx) < 2) continue;

            for (s <- groupIdx) {
                str blockStr = "";
                for (k <- [0 .. t]) {
                    blockStr += "|" + lineKey[s + k];
                }
                exactMap[blockStr] ?= [];
                exactMap[blockStr] += [s];
            }
        }

        /* --------------------------------------------------------------------
         * Step 3.3: Creating the actual Pairs
         * -------------------------------------------------------------------- */
        for (bk <- exactMap) {
            list[int]   group   = exactMap[bk];
            int         m       = size(group);
            int         rep     = group[0];

            if (m < 2){ continue; }

            for (idx <- [1 .. m]) {
                int other = group[idx];

                Location loc1 = toLocation(lines, rep, t);
                Location loc2 = toLocation(lines, other, t);

                clones += clone(
                    [loc1, loc2],                   // 2 Locations (Block A and B)
                    t,                              // Block size
                    cloneType,                      // Clone Type
                    "<h>-<rep>-<other>",            // ID
                    "TokenClone_<rep>_<other>"      // Clone Class Name
                );
            }
        }
    }

    return clones;
}