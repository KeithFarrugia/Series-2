module Conf

/* ============================================================================
 *                           Project Configuration
 * ----------------------------------------------------------------------------
 * Set the target project for clone detection and analysis.
 * Change this value to the project you want to run the clone detection on
 * ============================================================================ 
 */
// public loc projectRoot = |project://hsqldb-2.3.1|; 
// public loc projectRoot = |project://series2/clone-demo|;
public loc projectRoot = |project://smallsql0.21_src|;

// Change this to match the absolute filepath of the project you're analysing 
public str rootPath = "/dev/software_evo/Series-2/clone-demo";

/* ============================================================================
 *                           Clone Output Configuration
 * ----------------------------------------------------------------------------
 *  File location for the clones.json output and detection thresholds.
 * ============================================================================ 
 */
// The below is used to create the clones.json
public loc clonesJson = |project://series2/clones.json|;

/* ============================================================================
 *                           Constants
 * ----------------------------------------------------------------------------
 * ============================================================================ 
 */
public int  DUPLICATION_THRESHOLD   = 6;
public int  MASS_THRESHOLD          = 12;
public real SIMILARITY_THRESHOLD    = 0.70;

/* ============================================================================
 *                           Clone Data Structures
 * ----------------------------------------------------------------------------
 *  Definitions for Clone, Location, and ProjectClones JSON representations.
 * ============================================================================ */
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

/* ============================================================================
 *                           Lines of Code Output Configuration
 * ----------------------------------------------------------------------------
 *  File location for the lines.json output and supporting data structures.
 * ============================================================================ */
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