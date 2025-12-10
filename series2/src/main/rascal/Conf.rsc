module Conf

public str rootPath = "/dev/software_evo/Series-2/smallsql0.21_src"; // clone-demo";
public loc clonesJson = |project://series2/clones.json|;
public loc linesJson = |project://series2/lines.json|;

public loc projectRoot = |project://smallsql0.21_src|;

public data Clone = clone(
    list [Location] locations,
    int fragmentLength,
    int cloneType,
    str _id,
    str name
);

// Ignore for now
// Represents an individual location in the JSON 'locations' list
public data Location = location(
    str filePath,
    int startLine,
    int endLine
);

// Represents the entire JSON structure
public data ProjectClones = projectClones(
    str projectRoot,
    list[Clone] clones
);

// For lines.json
// Maps to the file object in JSON
public data FileMetrics = fileMetrics(
    str name, 
    str filePath, 
    int linesOfCode
);

// Maps to the module object in JSON
public data ModuleMetrics = moduleMetrics(
    str name, 
    list[FileMetrics] files
);

// Maps to the top-level project object in JSON
public data ProjectMetrics = projectMetrics(
    str projectRoot, 
    list[ModuleMetrics] modules
);