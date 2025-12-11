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


map[node, lrel[node, loc]] buckets  = ();
map[int, set[node]] massIndex = (); 
// 2. Cache map: stores the result of unsetRec(node) to avoid recalculation
map[node, node] normalizedNodeCache = (); 
// CONSTANT: Defines the range for mass comparison (e.g., 10% similarity in mass)
private real MASS_WINDOW_PERCENT = 0.10;

list [Clone] findClonesOfType3AST(){
    buckets  = ();
    list[Declaration] ast = genASTFromProject(projectRoot);

    visit (ast) {
        case node x: {
            int currentMass = mass(x);
            if (currentMass >= MASS_THRESHOLD) {
                normalizedNodeCache[x] = unsetRec(x);
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
void addNodeToMap(
    node n // The ORIGINAL node (with location)
) {
    loc location = getLocation(n.src);

    if (minNodeLines(location) == false) {
        return;
    }

    // 1. Caching & Key Retrieval (O(1))
    // FIX: Retrieve key from the cache, preventing redundant unsetRec calls.
    // FIX: The original node 'n' retains its location.
    node key = normalizedNodeCache[n]; 
    int currentMass = mass(key);
    
    num topSim = 0;
    node bestKeyMatch;

    // 2. Optimized Search (Mass Indexing)
    int massWindow = toInt(currentMass * MASS_WINDOW_PERCENT);
    int minMass = currentMass - massWindow;
    int maxMass = currentMass + massWindow;

    // FIX: Only iterate over buckets whose mass is close to the current node's mass.
    for (m <- domain(massIndex)) {
        if (m >= minMass && m <= maxMass) {
            for (buck <- massIndex[m]) {
                num similarity = calculateSimilarity(buck, key);
                
                if (similarity >= SIMILARITY_THRESHOLD && similarity > topSim) {
                    topSim = similarity;
                    bestKeyMatch = buck;
                }
            }
        }
    }

    // 3. Finalize Key and Update Index
    if (topSim > 0) {
        key = bestKeyMatch;
    } else {
        if (currentMass in massIndex) {
            massIndex[currentMass] += key;
        } else {
            massIndex[currentMass] = {key};
        }
    }

    // 4. LOCATION HANDLING: Check for location uniqueness and insert
    if (buckets[key]?) {
        bool alreadyExists = false;
        
        // Check if the exact location is already present (simple and robust)
        for (clonePair <- buckets[key]) {
            if (location == getLocation(clonePair[1])) {
                alreadyExists = true;
                break;
            }
        }
    
        if (alreadyExists == false) {
            // Check for containment/overlap only if files are the same, 
            // but for Type-3 we often relax this and rely on removeInternalCloneClasses.
            // For now, let's trust the input AST has non-overlapping locations 
            // and simply add the new unique instance.
            buckets[key] += <n, location>;
        }
    } else {
        buckets[key] = [<n,location>];
    }
}

map[node, lrel[node_loc, node_loc]] findClonesSets(){
    map[node, lrel[node_loc, node_loc]] clonesSet = ();

    for (bucket <- buckets) {
        println("New bucket");
        list[tuple[node, loc]] nodes = buckets[bucket];

        if (size(nodes) >= 2) {
            lrel[tuple[node, loc] L, tuple[node, loc] R] complementBucket = [];

            // Only compare the first element with the rest
            tuple[node,loc] first = nodes[0];
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