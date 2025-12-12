module Clones::AST::Type_3

import Clones::AST::Common_AST;
import Utility::TokenAST;
import IO;
import String;
import List;
import Set;
import Map;
import Node;
import Location;
import lang::java::m3::Core;
import lang::java::m3::AST;
extend lang::java::m3::TypeSymbol;
import util::Math;
import Utility::Reader;
import util::FileSystem;
import util::Reflective;
import Utility::CloneMerger;
import Conf;


map[int, lrel[node, loc]] buckets  = ();

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

    return applyTransitivity(mergeClonePairList(buildASTCloneList(removeInternalCloneClasses(findClonesSets()), 3)));
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
// Compute a simple fingerprint for fast pre-bucketing
void addNodeToMap(node n) {
    if (!n has src) return;

    loc location = getLocation(n.src);
    if (!minNodeLines(location)) return;

    // Precompute clean node once
    node clean = unsetRec(n);
    tuple[node, loc] entry = <n, location>;

    // Use mass as coarse fingerprint
    int fp = mass(n);

    // Create bucket for this mass if it does not exist
    if (!buckets[fp]?) {
        buckets[fp] = [];
    }

    // Find best match within this bucket only
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

    // If a similar node was found, merge with that node's bucket
    if (bestSim > 0) {
        // Add to the same mass bucket
        buckets[fp] += entry;
    } else {
        buckets[fp] += entry;
    }
}

map[node, lrel[node_loc, node_loc]] findClonesSets() {
    map[node, lrel[node_loc, node_loc]] clonesSet = ();

    for (fp <- domain(buckets)) {  // fp is int, not node
        list[tuple[node, loc]] nodes = buckets[fp];

        if (size(nodes) >= 2) {
            lrel[tuple[node, loc] L, tuple[node, loc] R] complementBucket = [];

            // Only compare the first element with the rest
            tuple[node, loc] first = nodes[0];
            for (j <- [1..size(nodes)-1]) {
                complementBucket += [<first, nodes[j]>];
            }

            // Add pairs to the clonesSet map
            for (treeRelation <- complementBucket) {
                node key = treeRelation[0][0];
                if (clonesSet[key]?) {
                    clonesSet[key] += treeRelation;
                } else {
                    clonesSet[key] = [treeRelation];
                }
            }
        }
    }
    println("Found Clones");
    return clonesSet;
}

void printCloneSets(map[node, lrel[node_loc, node_loc]] clonesSet) {
    int classId = 1;

    for (k <- domain(clonesSet)) {
        println("==========================================");
        println("Clone Class <classId>");
        println("AST Key:");
        println("<k>");
        println("Pairs:");

        for (<L, R> <- clonesSet[k]) {
            println("  \t (< L[1] >)  \nCLONE OF\n \t <R[1] >");
        }

        classId += 1;
        println("");
    }
}