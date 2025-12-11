module series2::type3

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import Map;
import util::Math;
import String;
import analysis::graphs::Graph;

int MIN_METHOD_SIZE = 10;  // Match Type-1/2 for consistency
int N_GRAM_SIZE = 5;
real SIMILARITY_THRESHOLD = 0.65; 

data AbstractNode 
    = aIf(bool hasElse) 
    | aLoop(str loopType) 
    | aBlock() 
    | aAssign(str op)        
    | aCall(int args)        
    | aVar() 
    | aReturn(bool hasVal)
    | aOp(str op); 

alias MethodSequence = tuple[loc id, list[AbstractNode] seq, int size];

public list[Declaration] getASTs(loc projectLocation) {
    M3 model;
    if (exists(projectLocation + "pom.xml")) {
        model = createM3FromMavenProject(projectLocation);
    } else {
        model = createM3FromDirectory(projectLocation);
    }
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

Statement sanitize(Statement body) {
    return visit(body) {
        case \expressionStatement(\methodCall(_, name, _)) => \empty()
            when name[0] == "println" || name[0] == "print"
        
        case \expressionStatement(\methodCall(_, _, name, _)) => \empty()
            when name[0] == "println" || name[0] == "print"
    };
}

list[AbstractNode] linearize(Statement body) {
    list[AbstractNode] seq = [];
    visit(body) {
        // Control Flow
        case \if(_,_) : seq += aIf(false);
        case \if(_,_,_) : seq += aIf(true); 
        case \foreach(_,_,_) : seq += aLoop("foreach");
        case \for(_,_,_,_) : seq += aLoop("for");
        case \while(_,_) : seq += aLoop("while");
        case \do(_,_) : seq += aLoop("do");
        case \block(_) : seq += aBlock();
        
        // Assignments
        case \assignment(_,op,_) : seq += aAssign(op);

        // Operators
        case \times(_,_) : seq += aOp("*");
        case \divide(_,_) : seq += aOp("/");
        case \remainder(_,_) : seq += aOp("%");
        case \plus(_,_) : seq += aOp("+");
        case \minus(_,_) : seq += aOp("-");
        
        // Function calls
        case \methodCall(_, _, args) : seq += aCall(size(args));
        case \methodCall(_, _, _, args) : seq += aCall(size(args));
        
        // Returns
        case \return(_) : seq += aReturn(true);
        case \return() : seq += aReturn(false);

        // Variables
        case \variable(_,_) : seq += aVar();
        case \variable(_,_,_) : seq += aVar();
    }
    return seq;
}

list[MethodSequence] extractSequences(list[Declaration] asts) {
    list[MethodSequence] methods = [];
    visit(asts) {
        case m: \method(_, _, _, _, _, _, Statement impl): {
            Statement cleanImpl = sanitize(impl);
            list[AbstractNode] seq = linearize(cleanImpl);

            if (size(seq) >= MIN_METHOD_SIZE) {
                methods += <m.src, seq, size(seq)>;
            }
        }
        case c: \constructor(_, _, _, _, Statement impl): {
            Statement cleanImpl = sanitize(impl);
            list[AbstractNode] seq = linearize(cleanImpl);

            if (size(seq) >= MIN_METHOD_SIZE) {
                methods += <c.src, seq, size(seq)>;
            }
        }
    }
    return methods;
}

set[str] createNGrams(list[AbstractNode] seq) {
    set[str] grams = {};
    if (size(seq) < N_GRAM_SIZE) return grams;
    
    for (int i <- [0 .. size(seq) - N_GRAM_SIZE + 1]) {
        list[AbstractNode] window = slice(seq, i, N_GRAM_SIZE);
        grams += toString(window); 
    }
    return grams;
}

public set[set[loc]] detectClones(list[Declaration] asts) {
    println("1. Linearizing ASTs");
    list[MethodSequence] methods = extractSequences(asts);
    int totalMethods = size(methods);

    println("2. Indexing");
    map[str, list[int]] index = ();
    map[int, int] methodNumGrams = (); 
    
    for (int i <- [0..totalMethods]) {
        set[str] grams = createNGrams(methods[i].seq);
        methodNumGrams[i] = size(grams);
        // Put for each gram the indices of the methods into a list where the gram is active
        for (str g <- grams) {
            index[g] = (index[g] ? []) + i;
        }
    }

    println("3. Detecting clones");
    rel[loc, loc] clonePairs = {};
    for (int i <- [0..totalMethods]) {
        set[str] grams = createNGrams(methods[i].seq);
        if (isEmpty(grams)) continue;
        
        map[int, int] overlaps = ();
        for (str g <- grams) {
            if (g in index) {
                // index[g] is a list of methods where gram g occurs
                for (int otherIdx <- index[g]) {
                    // Only count overlaps "forward" to avoid double counting
                    if (otherIdx > i) { 
                        overlaps[otherIdx] = (overlaps[otherIdx] ? 0) + 1;
                    }
                }
            }
        }

        for (int otherIdx <- overlaps) {
            int shared = overlaps[otherIdx];
            int sizeA = methodNumGrams[i];
            int sizeB = methodNumGrams[otherIdx];
            int minSize = min(sizeA, sizeB);
            int maxSize = max(sizeA, sizeB);

            // Skip if methods differ too much in size (more than 3x difference)
            // This prevents false positives between very different methods
            if (maxSize > minSize * 2) continue;

            // Use Dice coefficient for Type-3 (more tolerant to size differences than Jaccard)
            real sim = 2.0 * toReal(shared) / toReal(sizeA + sizeB);

            if (sim >= SIMILARITY_THRESHOLD) {
                clonePairs += <methods[i].id, methods[otherIdx].id>;
            }
        }
    }
    return analysis::graphs::Graph::connectedComponents(clonePairs);
}

public void mainAlgorithm(loc projectLoc) {
    println("=== Type-3 Clone Detection (N-gram based) ===");
    println("Project: <projectLoc>");
    println("");
    
    list[Declaration] asts = getASTs(projectLoc);
    set[set[loc]] cloneClasses = detectClones(asts);
    
    println("\nFound <size(cloneClasses)> Type-3 clone classes.\n");
    
    int classId = 1;
    int totalInstances = 0;
    for (set[loc] cc <- cloneClasses) {
        println("Clone Class <classId>: <size(cc)> instances");
        for (loc l <- cc) {
            println("  - <l>");
        }
        totalInstances += size(cc);
        classId += 1;
    }
    println();
    
    println("Type-3 Clone Detection Statistics:");
    println("Number of clone instances: <totalInstances>");
    println("Number of clone classes: <size(cloneClasses)>");
}