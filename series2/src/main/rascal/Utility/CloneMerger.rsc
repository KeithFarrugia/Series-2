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