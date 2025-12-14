module Utility::Common_AST



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
import Conf;
import Utility::CleanCode;



/* ============================================================================
 *                        Constants / Configuration
 * ----------------------------------------------------------------------------
 * node_loc : Makes it easier then writing the entire type  
 * ============================================================================ */
 
alias node_loc = tuple[node, loc];





/* ============================================================================
 *                                 mass
 * ----------------------------------------------------------------------------
 *  Computes the number of nodes in a subtree rooted at the given node.
 * ============================================================================
 */
int mass(node n) {
    int m = 0;
    visit(n) {
        case node _: m += 1;
    }
    return m;
}

/* ============================================================================
 *                              getLocation
 * ----------------------------------------------------------------------------
 * Identity wrapper for a location object. (This is because .src returns a 
 * value not a location so instead we typecast it through this)
 * ============================================================================
 */
loc getLocation(loc l) {
    return l;
}
/* ============================================================================
 *                             minNodeLines
 * ----------------------------------------------------------------------------
 *  Checks if a location spans at least 6 lines (DUPLICATION_THRESHOLD).
 * ============================================================================
 */
public bool minNodeLines(loc key) {
    return (key.end.line - key.begin.line) >= 6;
}

/* ============================================================================
 *                         calculateSimilarity
 * ----------------------------------------------------------------------------
 * Computes AST similarity using the formula: 2*S / (2*S + L + R)
 * where S = shared nodes, L = nodes only in t1, R = nodes only in t2.
 * Sørensen-Dice
 * ============================================================================
 */
public num calculateSimilarity(node t1, node t2) {
    list[node] tree1 = [];
    list[node] tree2 = [];

    visit(t1) { case node x: tree1 += x; }
    visit(t2) { case node x: tree2 += x; }

    num s = size(tree1 & tree2);
    num l = size(tree1 - tree2);
    num r = size(tree2 - tree1);

    return (2 * s) / (2 * s + l + r);
}

/* ============================================================================
 *                            delSymmPairs
 * ----------------------------------------------------------------------------
 *  Removes symmetric duplicate clone pairs from a list, keeping only one
 *  canonical ordering per pair.
 * ============================================================================
 */
lrel[node_loc, node_loc] delSymmPairs(lrel[node_loc, node_loc] clonePairs) {
    set[str] seen = {};
    lrel[node_loc, node_loc] out = [];

    for (<L, R> <- clonePairs) {
        str keyL = "<L[1].uri>:<L[1].begin.line>:<L[1].end.line>";
        str keyR = "<R[1].uri>:<R[1].begin.line>:<R[1].end.line>";

        str canonical =  
            (keyL <= keyR)    ? 
            keyL + "|" + keyR : 
            keyR + "|" + keyL ;

        if (!(canonical in seen)) {
            seen += {canonical};
            out += [<L, R>];
        }
    }

    return out;
}






/* ============================================================================
 *                         checkForInnerClones
 * ----------------------------------------------------------------------------
 *  Returns subnodes of a tree that are fully contained in existing clone sets.
 * ============================================================================
 */
list[node] checkForInnerClones(tuple[node, loc] tree,
                               map[node, lrel[node_loc, node_loc]] cloneSet) {
    list[node] subNodes = [];

    visit(tree[0]) {
        case node x: {
            if (x != tree[0] && x.src?) {
                loc location = getLocation(x.src);
                tuple[node, loc] current = <x, location>;
                bool member = false;

                for (cRoot <- domain(cloneSet)) {
                    for (currentPair <- cloneSet[cRoot]) {
                        if (
                            (
                                current[1] <= currentPair[0][1] && 
                                currentPair[0][0] == current[0]
                            ) || (
                                current[1] <= currentPair[1][1] && 
                                currentPair[1][0] == current[0] 
                            )
                        ) {
                            if (
                                cloneSet[current[0]]?      && 
                                size(cloneSet[current[0]]) == 
                                size(cloneSet[cRoot])
                            ) {
                                member = true;
                            }
                        }
                    }
                }

                if (member) {
                    subNodes += x;
                }
            }
        }
    }

    return subNodes;
}


/* ============================================================================
 *                               contains
 * ----------------------------------------------------------------------------
 *  Checks if the `inner` location is fully contained within the `outer` location.
 * ============================================================================
 */
public bool contains(loc outer, loc inner) {
    if (outer.uri != inner.uri) return false;
    return 
        outer.begin.line <= inner.begin.line && 
        outer.end.line   >= inner.end.line;
}

 /* ============================================================================
 *                    removeInternalCloneClasses
 * ----------------------------------------------------------------------------
 * Removes AST clone classes that are fully contained in larger classes.
 * ============================================================================
 */
public map[node, lrel[node_loc, node_loc]] removeInternalCloneClasses(
    map[node, lrel[node_loc, node_loc]] cloneSet
) {
    println("\n==================================================================");
    println("Starting removeInternalCloneClasses");
    println("Initial cloneSet size <size(cloneSet)>");

    set[node] keysToRemove = {};

    for (node nodeKey <- cloneSet) {
        visit(nodeKey) {
            case node subKey: {
                if (subKey == nodeKey) break;
                else if (cloneSet[subKey]? && !(subKey in keysToRemove)) {
                    bool allContained = true;

                    for (i <- [0 .. size(cloneSet[subKey])-1]) {
                        tuple[node_loc, node_loc] pair = cloneSet[subKey][i];
                        <sn1, sl1> = pair[0];
                        <sn2, sl2> = pair[1];

                        bool foundParent = false;
                        for (<<_, l1>, <_, l2>> <- cloneSet[nodeKey]) {
                            if ((contains(l1, sl1) && contains(l2, sl2)) ||
                                (contains(l2, sl1) && contains(l1, sl2))) {
                                foundParent = true;
                                break;
                            }
                        }

                        if (!foundParent) {
                            allContained = false;
                            break;
                        }
                    }

                    if (allContained) keysToRemove += subKey;
                }
            }
        }
    }

    for (key <- keysToRemove) {
        cloneSet = delete(cloneSet, key);
    }

    println("Finished removeInternalCloneClasses");
    println("Final cloneSet size <size(cloneSet)>");

    return cloneSet;
}

/* ============================================================================
 *                        buildASTCloneList
 * ----------------------------------------------------------------------------
 *  Converts a map of clone sets into a list of Clone objects.
 *  Merges all unique locations per root node and computes max fragment size.
 * ============================================================================
 */
list[Clone] buildASTCloneList(
    map[node, lrel[node_loc, node_loc]] cloneSet, int cloneType
) {
    list[Clone] result = [];

    for (root <- domain(cloneSet)) {
        set[Location] currentLocations = {};
        for (<L, R> <- cloneSet[root]) {
            Location loc1 = location(
                stripCompilationUnitPrefix(L[1].uri),
                L[1].begin.line,
                L[1].end.line
            );
            Location loc2 = 
                location(stripCompilationUnitPrefix(R[1].uri),
                R[1].begin.line,
                R[1].end.line
            );
            currentLocations += {loc1, loc2};
        }

        int maxLength = 0;
        for (l <- currentLocations) {
            int len = l.endLine - l.startLine + 1;
            if (len > maxLength) maxLength = len;
        }

        str id = "<root>";
        str name = "ASTClone_Class_<size(result)>";

        result += clone(
            toList(currentLocations), 
            maxLength, 
            cloneType, 
            id, 
            name
        );
    }

    return result;
}