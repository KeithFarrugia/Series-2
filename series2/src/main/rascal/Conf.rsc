module Conf

// Change this value to the project you want to run the clone detection on
public loc projectRoot = |project://hsqldb-2.3.1|; 

// Change this to match the absolute filepath of the project you're analysing 
public str rootPath = "/dev/software_evo/Series-2/hsqldb-2.3.1";

// ===========================
// The below is used to create the clones.json
public loc clonesJson = |project://series2/clones.json|;

// Represents a clone class which contains a type, and a list of cloned locations,
// The rest are needed for frontend visualisation and uniqueness 
public data Clone = clone(
    list [Location] locations,
    int fragmentLength,
    int cloneType,
    str _id,
    str name
);

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

// ===========================
// The below is used to create the lines.json
public loc linesJson = |project://series2/lines.json|;

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