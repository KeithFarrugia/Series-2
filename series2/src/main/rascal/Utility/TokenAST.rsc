module Utility::TokenAST

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
 *                               TokenizedLine ADT
 * ----------------------------------------------------------------------------
 *  Represents a single line of tokenised code. Stores:
 *    - the line number
 *    - full source location
 *    - the set of extracted tokens for that line
 * ============================================================================
 */
data TokenizedLine = line(
    int       lineNumber,  // The line number in the file
    loc       sourceLoc,   // Original source location
    set[str]  tokens       // Set of tokens belonging to this line
);
/* ============================================================================
 *                          Sort By Source Location 
 * ----------------------------------------------------------------------------
 *  Sort a list of TokenizedLine by source location (beginning line)
 * ============================================================================
 */
list[TokenizedLine] sortBySourceLoc(list[TokenizedLine] lines) {
    return sort(lines,
      bool(TokenizedLine a, TokenizedLine b) {
         return getBeginLine(a.sourceLoc) < getBeginLine(b.sourceLoc);
      }
    );
}
/* ============================================================================
 *                               Tokenise AST
 * ----------------------------------------------------------------------------
 *  Tokenises a given list of declarations.
 * ============================================================================
 */
list[TokenizedLine] tokeniseAST(list[Declaration] ast, bool normalise){
    list[TokenizedLine] tokenisedAST = [];
    if(normalise){
        for (a <- ast) {
            Declaration norm    = normaliseDeclaration(a);
            tokenisedAST       += sortBySourceLoc(tokenizeLines(norm));
        
        }
    }else{
        for (a <- ast) {
            tokenisedAST       += sortBySourceLoc(tokenizeLines(a));
        
        }
    }
    return tokenisedAST;
}


/* ============================================================================
 *                                normaliseNode
 * ----------------------------------------------------------------------------
 *  Normalises selected AST nodes (node n) by collapsing structure to
 *  abstract placeholders or removing non-essential subtree information.
 *  Returns a string representation of the simplified node
 *  (or empty string when no normalisation applies).
 * ============================================================================
 */
str normaliseNode(node n) {
    switch (n) {
        
        /* --------------------------------------------------------------------
         *  Case 1: method statements
         * --------------------------------------------------------------------
         */
        case \method(_, _, Type \return, _, list[Declaration] parameters, _, _):
            return toString(
                unsetRec((
                    \method( [], [], \return, id("ID"), parameters, [], \empty() )
                ))
            );

        /* --------------------------------------------------------------------
         *  Case 2: block statements
         * --------------------------------------------------------------------
         */
        case \block(list[Statement] _):
            return toString(\empty());

        /* --------------------------------------------------------------------
         *  Other control- or declaration-like nodes - parameter, for-loop, class
         * --------------------------------------------------------------------
         */
        case \parameter(_, _, _, _):
            return "empty()";

        case \for(_, _, _, _):
            return toString(
                unsetRec( \for([], [], \empty()) )
            );

        case \for(_, _, _):
            return toString(
                unsetRec( \for([], [], \empty()) )
            );

        case \class(_, Expression name, _, _, _, _):
            return toString(
                unsetRec( \class([], name, [], [], [], []) )
            );

        case \class(_):
            return toString( 
                unsetRec(\class([]))
            );

        /* --------------------------------------------------------------------
         *  Default: any other AST node kind - no normalisation mapping
         * --------------------------------------------------------------------
         */
        default:
            return "";
    }
}

/* ============================================================================
 *                            normaliseDeclaration
 * ----------------------------------------------------------------------------
 *  Normalises a Declaration tree by replacing all literal values, identifiers,
 *  and primitive types with generic placeholder forms (e.g., "ID", "LIT",
 *  simpleType("TYPE")).  
 *
 *  This is useful for clone detection, structural comparison, and hashing,
 *  since semantic differences such as names or literal values are removed.
 * ============================================================================
 */

Declaration normaliseDeclaration(Declaration d) {

    d = visit(d) {

        /* ---------------------------- Identifiers --------------------------- */
        case \id                (_)         => \id              ("ID")

        /* ----------------------------- Literals ----------------------------- */
        case \stringLiteral     (_)         => \stringLiteral   ("STR")
        case \textBlock         (_)         => \textBlock       ("LIT")
        case \number            (_)         => \number          ("LIT")
        case \characterLiteral  (_)         => \characterLiteral("LIT")
        case \booleanLiteral    (_)         => \booleanLiteral  ("LIT")

        /* ------------------------------ Types ------------------------------- */
        case \simpleType        (_)         => \simpleType        (id("TYPE"))
        case \qualifiedType     (_, _, _)   => \qualifiedType     ([], id("TYPE"), id("TYPE"))
        case \arrayType         (_)         => \arrayType         (simpleType (id("TYPE")))
        case \parameterizedType (_, _)      => \parameterizedType (simpleType (id("TYPE")), [])
        case \unionType         (_)         => \unionType         ([simpleType(id("TYPE"))])
        case \intersectionType  (_)         => \intersectionType  ([simpleType(id("TYPE"))])
        case \wildcard          (_)         => \simpleType        (id("TYPE"))

        /* --------------------------- Primitives ----------------------------- */
        case \int               ()          => \simpleType(id("TYPE"))
        case \float             ()          => \simpleType(id("TYPE"))
        case \long              ()          => \simpleType(id("TYPE"))
        case \double            ()          => \simpleType(id("TYPE"))
        case \byte              ()          => \simpleType(id("TYPE"))
        case \short             ()          => \simpleType(id("TYPE"))
        case \char              ()          => \simpleType(id("TYPE"))
        case \string            ()          => \simpleType(id("TYPE"))
        case \boolean           ()          => \simpleType(id("TYPE"))
        case \void              ()          => \simpleType(id("TYPE"))
    };

    return d;
}

/* ============================================================================
 *                                getBeginLine
 * ----------------------------------------------------------------------------
 *  Helper: extracts the starting line number from a location.
 * ============================================================================
 */
int getBeginLine(loc l) {
    return l.begin.line;
}


/* ============================================================================
 *                                getEndLine
 * ----------------------------------------------------------------------------
 *  Helper: extracts the ending line number from a location.
 * ============================================================================
 */
int getEndLine(loc l) {
    return l.end.line;
}


/* ============================================================================
 *                                tokenizeLines
 * ----------------------------------------------------------------------------
 *  Walks a Compilation Unit (Declaration) and collects tokens grouped by the
 *  line they originate from. Stores:
 *    - a set of token strings per line
 *    - the full loc of the first element mapped to that line
 *
 *  Returns: list[TokenizedLine] sorted by ascending line number.
 * ============================================================================
 */
list[TokenizedLine] tokenizeLines(Declaration cu) {

    // 1. Map of line number → set of token strings
    map[int, set[str]] byLine = ();

    // 2. Map of line number → source loc
    map[int, loc] locByLine = ();

    visit(cu) {
        case node n: {
            if (n.src?) {
                nLoc = n.src;
                int line = getBeginLine(nLoc);

                // Store root loc of the line
                locByLine[line] = nLoc;

                // Initialise set if first time referencing this line
                if (!(byLine[line]?)) {
                    byLine[line] = {};
                }

                str token = normaliseNode(n);

                if (token == "") {
                    tuple[list[node], bool] subNodes = filterOutSubNodes(n);

                    if (!subNodes[1]) { // no children
                        byLine[line] += toString(unsetRec(n));
                    }

                    for (s <- subNodes[0]) {
                        byLine[line] += toString(unsetRec(s));
                    }
                }
                else if (token != "empty()") {
                    byLine[line] += token;
                }
            }
        }
    }

    // Sort by line number (domain(byLine) is a set[int])
    list[int] lines = sort([l | l <- domain(byLine)]);

    return [line(l, locByLine[l], byLine[l]) | l <- lines];
}


/* ============================================================================
 *                              filterOutSubNodes
 * ----------------------------------------------------------------------------
 *  Extracts child nodes of a parent that occupy the exact same line.
 *
 *  Returns:
 *    - list of matching subnodes
 *    - boolean indicating whether the parent actually has children
 * ============================================================================
 */
tuple[list[node], bool] filterOutSubNodes(node parent) {

    println("\n\nFILTERING OUT KIDS\n");

    list[node] subNodes = [];
    bool hasKids = false;

    println("PARENT:\n <toString(parent)[0 .. 100]> ...");

    visit(parent) {
        case node n: {
            println("CHILD:\n\t<toString(n)[0 .. 100]> ...");

            if (n.src?) {
                hasKids = true;

                if (getBeginLine(n.src) == getBeginLine(parent.src)
                 && getEndLine(n.src)   == getBeginLine(parent.src)) 
                {
                    subNodes += n;
                }
            }
        }
    }

    return <subNodes, hasKids>;
}
