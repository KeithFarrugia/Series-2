module Clones::AST::Type_1_2

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
import Utility::Reader;
import Utility::TokenAST;
import Utility::CloneMerger;
import Utility::Timings;
import Utility::Common_AST;
/* ============================================================================
 *                                 buckets
 * ----------------------------------------------------------------------------
 * Stores AST nodes grouped by their 'mass' signature for clone detection.
 * (Note: It is included here because the linter didn't recognise its Type)
 * ============================================================================
 */
map[node, lrel[node, loc]] buckets  = ();

/* ============================================================================
 *                     findClonesOfType1Or2AST
 * ----------------------------------------------------------------------------
 *  Entry point for AST-based Type-1 and Type-2 clone detection. Normalises
 *  AST nodes if required, builds node buckets, generates clone pairs, merges
 *  and applies transitive reduction.
 * ============================================================================
 */
list[Clone] findClonesOfType1Or2AST(int cloneType) {
                        buckets     = ();
    list[Declaration]   ast         = genASTFromProject(projectRoot);
    list[Declaration]   norm_ast    = [];

    if (cloneType == 2) {
        for (d <- ast)
            norm_ast += normaliseDeclaration(d);
    } else {
        norm_ast = ast;
    }

    visit (norm_ast) {
        case node x: {
            if (mass(x) >= MASS_THRESHOLD)
                addNodeToMap(x);
        }
    }

    datetime     t0 = now();
    list[Clone] clones = 
        applyTransitivity(
            mergeClonePairList(
                buildASTCloneList(
                    removeInternalCloneClasses(findClonesSets()),
                    cloneType
        )));
    datetime     t1 = now();

    println("Clone detection time  (AST Type <cloneType>) <calcTime(t0, t1)>");

    return clones;
}

/* ============================================================================
 *                               addNodeToMap
 * ----------------------------------------------------------------------------
 *  Adds a node to the buckets map if:
 *    - It contains at least the minimum number of lines
 *    - Stores node keyed by its mass signature
 * ============================================================================
 */
void addNodeToMap(node n) {
    loc location;

    if (n has src) {
        location = getLocation(n.src);
    } else {
        return;
    }

    if (!minNodeLines(location))
        return;

    println("<location>");

    node key = unsetRec(n);

    if (buckets[key]?) {
        if (location != buckets[key][0][1])
            buckets[key] += <key, location>;
    } else {
        buckets[key] = [<key, location>];
    }
}

/* ============================================================================
 *                             findClonesSets
 * ----------------------------------------------------------------------------
 *  Constructs clone sets from the buckets by computing all pairwise node
 *  combinations, removing reflective and symmetric pairs.
 * ============================================================================
 */
map[node, lrel[node_loc, node_loc]] findClonesSets() {
    map[node, lrel[node_loc, node_loc]] clonesSet = ();

    for (bucket <- buckets) {
        if (size(buckets[bucket]) >= 2) {

            lrel[tuple[node,loc] L, tuple[node,loc] R] complementBucket = [];
            complementBucket += buckets[bucket] * buckets[bucket];

            // Remove reflective pairs
            complementBucket = [p | p <- complementBucket, p.L != p.R];

            // Remove symmetric duplicates
            complementBucket = delSymmPairs(complementBucket);

            for (treeRelation <- complementBucket) {
                node key = treeRelation[0][0];

                if (clonesSet[key]?)
                    clonesSet[key] += treeRelation;
                else
                    clonesSet[key] = [treeRelation];
            }
        }
    }

    return clonesSet;
}
