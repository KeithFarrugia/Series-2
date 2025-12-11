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

// Helper: Check if two clones share at least one identical Location object.
// This is the correct condition for applying transitivity (A=B and B=C implies A=C).
bool shouldMerge(Clone c1, Clone c2) {
    // Convert the location lists to sets for efficient intersection check.
    set[Location] locs1 = toSet(c1.locations);
    set[Location] locs2 = toSet(c2.locations);
    
    // If the intersection is non-empty, they share an identical location.
    return size(locs1 & locs2) > 0;
}
public list[Clone] applyTransitivity(list[Clone] clones) {


    bool changed = true;

    while (changed) {
        changed = false;
        list[Clone] result = [];

        for (Clone c <- clones) {
            bool merged = false;

            // Iterate over the result list (clones already processed)
            for (i <- index(result)) {
                
                // 1. Use the STRONG transitivity condition
                if (shouldMerge(c, result[i])) {

                    // Deconstruct and reconstruct the clone objects
                    list[Location] locs1    = result[i].locations;
                    int fl1                 = result[i].fragmentLength;
                    int t1                  = result[i].cloneType;
                    str id1                 = result[i]._id;
                    str name1               = result[i].name;

                    list[Location] locs2       = c.locations;

                    // 2. Merge locations with deduplication using a set
                    set[Location] mergedLocsSet = toSet(locs1) + toSet(locs2);

                    // Convert the unique locations back to a list
                    list[Location] mergedLocs = toList(mergedLocsSet);

                    // 3. Replace the existing clone with the merged one
                    // Note: We arbitrarily keep the metadata (fl1, t1, id1, name1) from the first clone (result[i]).
                    result[i] = clone(mergedLocs, fl1, t1, id1, name1);

                    merged = true;
                    changed = true; // Signal that a merge occurred, requiring another pass
                    break;          // Stop searching for overlaps for clone 'c' and move to the next 'c'
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


// ------------------------------------------------------------
// Checks if two locations overlap or are adjacent
// ------------------------------------------------------------
bool overlapsOrAdjacent(Location a, Location b) {
    return a.filePath == b.filePath
        && a.startLine <= b.endLine + 1
        && b.startLine <= a.endLine + 1;
}

// ------------------------------------------------------------
// Merge two locations into one interval
// ------------------------------------------------------------
Location mergeLocations(Location a, Location b) {
    return location(
        a.filePath,
        min(a.startLine, b.startLine),
        max(a.endLine, b.endLine)
    );
}

// ------------------------------------------------------------
// Checks if two clone pairs overlap in aligned or swapped order
// ------------------------------------------------------------
bool clonePairsOverlap(Clone c1, Clone c2) {
    // aligned: c1.locations[0] ↔ c2.locations[0] AND c1.locations[1] ↔ c2.locations[1]
    bool aligned = overlapsOrAdjacent(c1.locations[0], c2.locations[0])
                && overlapsOrAdjacent(c1.locations[1], c2.locations[1]);

    // swapped: c1.locations[0] ↔ c2.locations[1] AND c1.locations[1] ↔ c2.locations[0]
    bool swapped = overlapsOrAdjacent(c1.locations[0], c2.locations[1])
                && overlapsOrAdjacent(c1.locations[1], c2.locations[0]);

    return aligned || swapped;
}

// ------------------------------------------------------------
// Merge two clone pairs into one (supports swapped order)
// ------------------------------------------------------------
Clone mergeClonePairs(Clone c1, Clone c2) {
    list[Location] merged = [];

    // Decide alignment
    bool aligned = overlapsOrAdjacent(c1.locations[0], c2.locations[0])
                && overlapsOrAdjacent(c1.locations[1], c2.locations[1]);

    if (aligned) {
        merged += [ mergeLocations(c1.locations[0], c2.locations[0]) ];
        merged += [ mergeLocations(c1.locations[1], c2.locations[1]) ];
    } else {
        // assume swapped
        merged += [ mergeLocations(c1.locations[0], c2.locations[1]) ];
        merged += [ mergeLocations(c1.locations[1], c2.locations[0]) ];
    }

    // Compute max fragment length
    int maxLength = max([
        merged[0].endLine - merged[0].startLine + 1,
        merged[1].endLine - merged[1].startLine + 1
    ]);

    return clone(
        merged,
        maxLength,
        c1.cloneType,
        c1._id,
        c1.name
    );
}

// ------------------------------------------------------------
// Merge all overlapping clone pairs in a list
// ------------------------------------------------------------
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




/*
 * Normalise a clone so that the location pair is always ordered the same.
 * This way [locA, locB] is equal to [locB, locA].
 */
Clone normalise(Clone c) {
    list[Location] locs = c.locations;
    if (locs[0] < locs[1]) {
        return clone([locs[0], locs[1]], c.fragmentLength, c.cloneType, c._id, c.name);
    } else {
        return clone([locs[1], locs[0]], c.fragmentLength, c.cloneType, c._id, c.name);
    }
}

/*
 * Create a strong equality key for exact-match clones.
 * Two clones are considered equal ONLY if:
 *   - locations match EXACTLY
 *   - fragmentLength matches
 */
str cloneKey(Clone c) {
    Location a = c.locations[0];
    Location b = c.locations[1];

    return "<a.filePath>:<a.startLine>-<a.endLine>__"
         + "<b.filePath>:<b.startLine>-<b.endLine>__"
         + "<c.fragmentLength>";
}

/*
 * Merge clones with preference:
 *   Type 1 > Type 2 > Type 3
 */
list[Clone] mergeCloneTypes(list[Clone] clones) {
    map[str, Clone] best = ();

    for (c <- clones) {
        Clone n = normalise(c);
        str key = cloneKey(n);

        if (key notin best) {
            best[key] = n;        // first clone of this exact pair
        } else {
            Clone existing = best[key];

            // keep the one with the lowest cloneType number (1 is strongest)
            if (n.cloneType < existing.cloneType) {
                best[key] = n;
            }
        }
    }

    return [best[key] | key <- best];
}