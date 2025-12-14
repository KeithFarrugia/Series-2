module Clones::AST::Type_3


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
import Utility::Common_AST;
import Utility::Timings;

/* ============================================================================
 *                                 buckets
 * ----------------------------------------------------------------------------
 *  Stores AST nodes grouped by coarse mass fingerprint for approximate Type-3
 *  clone detection.
 * ============================================================================
 */
map[int, lrel[node, loc]] buckets  = ();

/* ============================================================================
 *                       findClonesOfType3AST
 * ----------------------------------------------------------------------------
 *  Entry point for AST-based Type-3 clone detection. Traverses AST, buckets
 *  nodes by mass and similarity, and builds clone pairs.
 * ============================================================================
 */
list [Clone] findClonesOfType3AST(){
    buckets  = ();
    list[Declaration] ast = genASTFromProject(projectRoot);

    visit (ast) {
        case node x: {
            int currentMass = mass(x);
            if (currentMass >= MASS_THRESHOLD) {
                addNodeToMap(x);
            }
        }
    }
    
    datetime     t0 = now();
    list[Clone] clones = 
        mergeClonePairList(
            buildASTCloneList(
                removeInternalCloneClasses(findClonesSets()),
                3
        ));
    datetime     t1 = now();

    println("Clone detection time  (AST Type 3) <calcTime(t0, t1)>");

    return clones;
}

/* ============================================================================
 *                             addNodeToMap()
 * ----------------------------------------------------------------------------
 * Basically: 
 * A node is added to the bucket if:
 *      - It contains the minimum number of lines required
 *      - This is stored in the DUPLICATION_THRESHOLD at "Clones::AST::Common_AST"
 *        Usually set to 6 lines.
 * ============================================================================
 */
void addNodeToMap(node n) {
    if (!n has src) return;

    loc location = getLocation(n.src);
    if (!minNodeLines(location)) return;

    node clean = unsetRec(n);
    tuple[node, loc] entry = <n, location>;

    int fp = mass(n);

    buckets[fp] ?= [];

    list[tuple[node, loc]] bucket = buckets[fp];
    node bestKey = clean;
    num bestSim = 0;

    for (tuple[node, loc] existing <- bucket) {
        node existingNode = existing[0];
        num sim = calculateSimilarity(existingNode, clean);
        if (sim >= SIMILARITY_THRESHOLD && sim > bestSim) {
            bestSim = sim;
            bestKey = existingNode;
        }
    }

    // Add to the bucket regardless; merged logic keeps duplicates safe
    buckets[fp] += entry;
}
/* ============================================================================
 *                             findClonesSets
 * ----------------------------------------------------------------------------
 *  Constructs clone sets from mass buckets by comparing the first node in
 *  each bucket with the others and collecting pairs into a map.
 * ============================================================================
 */
map[node, lrel[node_loc, node_loc]] findClonesSets() {
    map[node, lrel[node_loc, node_loc]] clonesSet = ();

    for (fp <- domain(buckets)) {
        list[tuple[node, loc]] nodes = buckets[fp];

        if (size(nodes) >= 2) {
            lrel[tuple[node, loc] L, tuple[node, loc] R] complementBucket = [];

            tuple[node, loc] first = nodes[0];
            for (j <- [1 .. size(nodes) - 1]) {
                complementBucket += [<first, nodes[j]>];
            }

            for (treeRelation <- complementBucket) {
                node key = treeRelation[0][0];
                clonesSet[key] ?= [];
                clonesSet[key] += treeRelation;
            }
        }
    }

    return clonesSet;
}