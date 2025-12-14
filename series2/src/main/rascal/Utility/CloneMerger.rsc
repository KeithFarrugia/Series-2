module Utility::CloneMerger

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

/* ============================================================================
 *                          Clone Transitivity
 * ----------------------------------------------------------------------------
 * Helper: Check if two clones share at least one identical Location object.
 * If true, they can be merged (transitivity: A=B and B=C implies A=C).
 * ============================================================================
 */
bool shouldMerge(Clone c1, Clone c2) {
    set[Location] locs1 = toSet(c1.locations);
    set[Location] locs2 = toSet(c2.locations);

    return size(locs1 & locs2) > 0;
}

/* ============================================================================
 *                          Apply Transitivity
 * ----------------------------------------------------------------------------
 * Iteratively merges all clones that share a location until no further
 * merges are possible.
 * ============================================================================
 */
public list[Clone] applyTransitivity(list[Clone] clones) {
    bool changed = true;

    while (changed) {
                    changed = false;
        list[Clone] result  = [];

        for (Clone c <- clones) {
            bool merged = false;
            
            /* -------------------------------------------------
             * Iterate over the result list (clones already 
             * processed)
             * ------------------------------------------------- */
            for (i <- index(result)) {
                
                /* -------------------------------------------------
                 * 1. Use the STRONG transitivity condition
                 * ------------------------------------------------- */
                if (shouldMerge(c, result[i])) {

                    // Deconstruct and reconstruct the clone objects
                    list[Location] locs1    = result[i].locations;
                    int fl1                 = result[i].fragmentLength;
                    int t1                  = result[i].cloneType;
                    str id1                 = result[i]._id;
                    str name1               = result[i].name;

                    list[Location] locs2       = c.locations;

                    /* -------------------------------------------------
                     * 2. Merge locations with deduplication using a set
                     * ------------------------------------------------- */
                    set[Location] mergedLocsSet = toSet(locs1) + toSet(locs2);

                    // Convert the unique locations back to a list
                    list[Location] mergedLocs = toList(mergedLocsSet);

                    
                    /* -------------------------------------------------
                     * 3. Replace the existing clone with the merged one
                     * Note: We arbitrarily keep the metadata (fl1, t1, 
                     * id1, name1) from the first clone (result[i]).
                     * ------------------------------------------------- */
                    result[i] = clone(mergedLocs, fl1, t1, id1, name1);
                    
                    
                    /* -------------------------------------------------
                     * Signal that a merge occurred, requiring 
                     * another pass
                     * Stop searching for overlaps for clone 'c' and 
                     * move to the next 'c'
                     * ------------------------------------------------- */
                    merged  = true;
                    changed = true;
                    break;
                }
            }

            if (!merged) {
                result += [c];
            }
        }

        clones = result;
    }

    return clones;
}


/* ============================================================================
 *                          overlapsOrAdjacent
 * ----------------------------------------------------------------------------
 * Check if two locations overlap or are directly adjacent.
 * ============================================================================
 */
bool overlapsOrAdjacent(Location a, Location b) {
    return a.filePath == b.filePath
        && a.startLine <= b.endLine + 1
        && b.startLine <= a.endLine + 1;
}

/* ============================================================================
 *                          mergeLocations
 * ----------------------------------------------------------------------------
 * Merge two overlapping or adjacent locations into one interval.
 * ============================================================================
 */
Location mergeLocations(Location a, Location b) {
    return location(
        a.filePath,
        min(a.startLine, b.startLine),
        max(a.endLine, b.endLine)
    );
}

/* ============================================================================
 *                          clonePairsOverlap
 * ----------------------------------------------------------------------------
 * Check if two clone pairs overlap in aligned or swapped order.
 * ============================================================================
 */
bool clonePairsOverlap(Clone c1, Clone c2) {
    if (size(c1.locations) < 2 || size(c2.locations) < 2) return false;

    bool aligned = 
        overlapsOrAdjacent(c1.locations[0], c2.locations[0]) && 
        overlapsOrAdjacent(c1.locations[1], c2.locations[1]);

    bool swapped = 
        overlapsOrAdjacent(c1.locations[0], c2.locations[1]) && 
        overlapsOrAdjacent(c1.locations[1], c2.locations[0]);

    return aligned || swapped;
}


/* ============================================================================
 *                           mergeClonePairs
 * ----------------------------------------------------------------------------
 * Merge two overlapping clone pairs into a single clone.
 * ============================================================================
 */
Clone mergeClonePairs(Clone c1, Clone c2) {
    list[Location] merged = [];

    bool aligned = 
        overlapsOrAdjacent(c1.locations[0], c2.locations[0]) && 
        overlapsOrAdjacent(c1.locations[1], c2.locations[1]);

    if (aligned) {
        merged += [ mergeLocations(c1.locations[0], c2.locations[0]) ];
        merged += [ mergeLocations(c1.locations[1], c2.locations[1]) ];
    } else {
        merged += [ mergeLocations(c1.locations[0], c2.locations[1]) ];
        merged += [ mergeLocations(c1.locations[1], c2.locations[0]) ];
    }

    int maxLength = max([
        merged[0].endLine - merged[0].startLine + 1,
        merged[1].endLine - merged[1].startLine + 1
    ]);

    return clone(merged, maxLength, c1.cloneType, c1._id, c1.name);
}


/* ============================================================================
 *                           mergeClonePairList
 * ----------------------------------------------------------------------------
 * Iteratively merges all overlapping clone pairs in a list.
 * ============================================================================
 */
list[Clone] mergeClonePairList(list[Clone] clones) {
    bool changed = true;

    while (changed) {
        changed = false;
        list[Clone] newClones = [];
        set[int] mergedIndices = {};

        for (i <- index(clones)) {
            if (i in mergedIndices) continue;
            Clone current = clones[i];

            for (j <- index(clones)) {
                if (i == j || j in mergedIndices) continue;
                if (clonePairsOverlap(current, clones[j])) {
                    current = mergeClonePairs(current, clones[j]);
                    mergedIndices += {j};
                    changed = true;
                }
            }

            mergedIndices += {i};
            newClones += current;
        }

        clones = newClones;
    }

    return clones;
}



/* ============================================================================
 *                           normalise
 * ----------------------------------------------------------------------------
 * Ensure the two locations of a clone are always in a consistent order.
 * ============================================================================
 */
Clone normalise(Clone c) {
    list[Location] locs = c.locations;
    if (locs[0] < locs[1]) {
        return clone(
            [locs[0], locs[1]], 
            c.fragmentLength, 
            c.cloneType, 
            c._id, c.name
        );
    } else {
        return clone(
            [locs[1], locs[0]], 
            c.fragmentLength, 
            c.cloneType, 
            c._id, 
            c.name
        );
    }
}
/* ============================================================================
 *                           cloneKey
 * ----------------------------------------------------------------------------
 * Create a strong equality key for exact-match clones.
 * Two clones are considered equal ONLY if:
 *  - locations match EXACTLY
 *  - fragmentLength matches
 * ============================================================================
 */
str cloneKey(Clone c) {
    Location a = c.locations[0];
    Location b = c.locations[1];

    return "<a.filePath>:<a.startLine>-<a.endLine>__"
         + "<b.filePath>:<b.startLine>-<b.endLine>__"
         + "<c.fragmentLength>";
}


/* ============================================================================
 *                           mergeCloneTypes
 * ----------------------------------------------------------------------------
 * Merge exact-match clones, preferring Type 1 > Type 2 > Type 3.
 * ============================================================================
 */
list[Clone] mergeCloneTypes(list[Clone] clones) {
    map[str, Clone] best = ();

    for (c <- clones) {
        Clone n = normalise(c);
        str key = cloneKey(n);

        if (key notin best) {
            best[key] = n;
        } else {
            Clone existing = best[key];
            if (n.cloneType < existing.cloneType) {
                best[key] = n;
            }
        }
    }

    return [best[key] | key <- best];
}