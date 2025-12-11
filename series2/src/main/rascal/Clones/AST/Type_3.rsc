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

list [Clone] findClonesOfType3AST(){
    buckets  = ();
    list[Declaration] ast = genASTFromProject(projectRoot);
    list[Declaration] norm_ast = [];
    
    for(d <- ast){
        norm_ast += normaliseDeclaration(d);
    }


    visit (norm_ast) {
        case node x: {
            int currentMass = mass(x);
            if (currentMass >= MASS_THRESHOLD) {
                addNodeToMap(x);
            }
        }
    }

    return applyTransitivity(buildASTCloneList(removeInternalCloneClasses(findClonesSets()), 3));
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
    node n
) {
    loc location = getLocation(n.src);

    if (minNodeLines(location) == false) {
        return;
    }

    node key = unsetRec(n);
    n = unsetRec(n);
    int i = 0;
    num topSim = 0;
    node bestKeyMatch;

    for (buck <- domain(buckets)) {
        i += 1;
        num similarity = calculateSimilarity(buck, key);
        if (similarity >= SIMILARITY_THRESHOLD && similarity > topSim) {
            topSim = similarity;
            bestKeyMatch = buck;
        }
    }

    if (topSim > 0) {
        key = bestKeyMatch;
    }

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
            buckets[key] += <n,location>;
        }
    } else {
        buckets[key] = [<n,location>];
    }
}

map[node, lrel[node_loc, node_loc]] findClonesSets(){
    map[node, lrel[node_loc, node_loc]] clonesSet = ();

    for (bucket <- buckets) {
        list[tuple[node, loc]] nodes = buckets[bucket];

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