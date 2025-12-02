module Clones::AST::Type_3

import Clones::AST::Common_AST;
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
import util::FileSystem;
import util::Reflective;




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
    node key, node subTree, int cloneType, int similarityThreshold
) {
    loc     location            = getLocation(subTree.src);
    node    bestKeyMatch;


    if (minNodeLines(location) == false) {
        return;
    }

    /* ------------------------------------------------
     * Try and find the closest matching existing 
     * bucket that passes the similarity treshold
     * If we find one we will insert this node together
     * with it
     */
    int i       = 0;
    num topSim  = 0;
    for (buck <- domain(buckets)) {
        i += 1;
        num similarity = calculateSimilarity(buck, key);
        if (
            similarity >= similarityThreshold && 
            similarity >  topSim
        ) {
            topSim = similarity;
            bestKeyMatch = buck; 
        }
    }
    
    if (topSim > 0) {
        key = bestKeyMatch;
    }
    
    

    /* ------------------------------------------------
     * This insertes the bucket at the key
     */
    if (buckets[key]?) {
        bool allow = true;
        for (clonePair <- buckets[key]) {
            if (location < getLocation(clonePair[1])) {
                allow = false;
                break;
            } else if (getLocation(clonePair[1]) < location) {
                buckets[key] = buckets[key] - clonePair; 
            }
        }
    
        if (allow == true) {
            buckets[key] += <subTree,location>;
        }
    } else {
        buckets[key] = [<subTree,location>];
    }
}






void findClonesSets(){
    map[node, lrel[node_loc, node_loc]] clonesSet = ();

    for (bucket <- buckets) {
        if (size(buckets[bucket]) >= 2) {
            lrel[tuple[node,loc] L, tuple[node,loc] R] complementBucket = [];
            complementBucket += buckets[bucket] * buckets[bucket];
            // Removing reflective pairs
            complementBucket = [p | p <- complementBucket, p.L != p.R];
            // Cleanup symmetric clones, they are useless.
            complementBucket = delSymmPairs(complementBucket);
                
            for (treeRelation <- complementBucket) {
                if (clonesSet[treeRelation[0][0]]?) {
                    clonesSet[treeRelation[0][0]] += treeRelation;
                } else {
                    clonesSet[treeRelation[0][0]] = [treeRelation];
                }
            }
        }
    }
}