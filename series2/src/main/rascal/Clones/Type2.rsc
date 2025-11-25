module Clones::Type2

import IO;
import String;
import List;
import Set;
import Map;
import Utility::Hash;
import lang::java::m3::AST;

/*
 * Minimum number of physical source lines a clone must span.
 */
int DUPLICATION_THRESHOLD = 6;

/*
 * Entry point: count duplicated lines via AST clone detection.
 */
int countDuplicates(list[Declaration] asts) {
    list[Declaration] nodes = collectCloneNodes(asts);
    map[int, list[loc]] bucket = groupByHash(nodes);
    set[loc] duplicated = collectDuplicateLocations(bucket);

    return size(duplicated);
}

/*
 * Collect all AST nodes that can contain cloned code.
 */
list[Declaration] collectCloneNodes(list[Declaration] asts) {
    list[Declaration] result = [];

    for (cu <- asts) {
        visit(cu) {
            case stmt: Statement => result += [stmt];
            case block: \block(_) => result += [block];
            case method: \methodDeclaration(_, _, _, _, _, _, _) => result += [method];
            case ctor: \constructorDeclaration(_, _, _, _, _) => result += [ctor];
        }
    }

    return result;
}

/*
 * Filter + normalize + hash AST nodes.
 */
map[int, list[loc]] groupByHash(list[Declaration] nodes) {
    map[int, list[loc]] bucket = ();

    for (n <- nodes) {
        loc L = locOf(n);

        if (lines(L) < DUPLICATION_THRESHOLD)
            continue;

        Declaration norm = normalize(n);
        str s = toString(norm);
        int h = hash(s);

        if (h in bucket)
            bucket[h] += [L];
        else
            bucket[h] = [L];
    }

    return bucket;
}

/*
 * Collect duplicated line spans.
 */
set[loc] collectDuplicateLocations(map[int, list[loc]] bucket) {
    set[loc] duplicated = {};

    for (h <- bucket) {
        list[loc] occurrences = bucket[h];
        if (size(occurrences) < 2)
            continue;

        for (L <- occurrences) {
            println("Clone of hash <h> at <L>");
            duplicated += {L};
        }
    }

    return duplicated;
}

/*
 * Helper: count source lines covered by a location.
 */
int lines(loc L) = L.end.line - L.begin.line + 1;

/*
 * AST normalization for Type II clones.
 */
Declaration normalize(Declaration d) {
    visit(d) {
        case \id(_): replace \id("ID");
        case \stringLiteral(_): replace \stringLiteral("LIT");
        case \intLiteral(_): replace \intLiteral("LIT");
        case \booleanLiteral(_): replace \booleanLiteral("LIT");
        case \type(_, _): replace \type("TYPE");
    }

    return d;
}
