import { calculateFilteredDuplication } from "./data.js";

/* ------------- Build D3 hierarchy (modules -> files). value = linesOfCode ------------- */
export function buildHierarchy(data, moduleFilterSet, typeFilterSet, includeNoClones){
  // data is the file structure merged with raw clone ranges
  const root = { name: data.projectRoot, children: [] };
  const allCloneTypes = ['type1', 'type2', 'type3'];

  // Determine which type filters are active for the calculation
  // If no filters are checked, we treat it as 'show all'
  const activeTypeFilterSet = typeFilterSet.size > 0 ? typeFilterSet : new Set(allCloneTypes);

  for(const mod of data.modules){
    if(moduleFilterSet.size && !moduleFilterSet.has(mod.name)) continue;

    const modNode = { name: mod.name, children: [] };
    
    // Variables for module-level aggregation
    let modTotalDuplicationPercentWeighted = 0;
    let modTotalFileCount = 0;

    for(const file of mod.files){
      
      // Calculate the metrics based *only* on the active type filters
      const filteredMetrics = calculateFilteredDuplication(file, activeTypeFilterSet);
      
      let passesFilter = true;
      
      // Filtering Logic: Exclude files that have 0% duplication for the filtered type set
      if (typeFilterSet.size > 0 && !includeNoClones && filteredMetrics.duplicatedLines === 0) {
          passesFilter = false;
      }
      // If no type filters are active, all files (even 0% duplication) are included
      if (typeFilterSet.size === 0) {
          passesFilter = true; 
      }

      if(!passesFilter) continue; // Exclude file

      // leaf node
      const fileNode = {
        name: file.name,
        filePath: file.filePath,
        linesOfCode: file.linesOfCode || 0,
        duplicationPercent: filteredMetrics.duplicationPercent,
        duplicatedLines: filteredMetrics.duplicatedLines,
        mergedRanges: filteredMetrics.mergedRanges,
      };
      
      modNode.children.push(fileNode);

      // Accumulate the duplicationPercent of the files added to the module
      modTotalDuplicationPercentWeighted += fileNode.duplicationPercent;
      modTotalFileCount++;
    }

    // only add module if it has children after filtering
    if(modNode.children.length>0) {
      
      // Calculate Average Duplication Percent for the Module (Level 1)
      if (modTotalFileCount > 0) {
          modNode.duplicationPercent = modTotalDuplicationPercentWeighted / modTotalFileCount;
      } else {
          modNode.duplicationPercent = 0;
      }

      // Add the file count metric
      modNode.fileCount = modTotalFileCount;

      root.children.push(modNode);
    }
  }
  
  // Attach project-wide averages
  root.projectMetrics = data.projectMetrics;

  // Aggregrate root metrics
  let rootTotalDuplicationPercentWeighted = 0;
  let rootTotalFileCount = 0;

  if(root.children.length > 0) {
      for(const child of root.children){
          // Duplication: Calculate weighted average using file count
          rootTotalDuplicationPercentWeighted += (child.duplicationPercent || 0) * child.fileCount;
          rootTotalFileCount += child.fileCount;
      }
      
      // Calculate the weighted average duplication percent for the project root
      if (rootTotalFileCount > 0) {
          // Weighted average, rounded to 1 decimal
          root.duplicationPercent = Math.round((rootTotalDuplicationPercentWeighted / rootTotalFileCount) * 10) / 10;
      } else {
          root.duplicationPercent = 0;
      }
      
      // Total file count for the root
      root.fileCount = rootTotalFileCount;
  } else {
      root.duplicationPercent = 0;
      root.fileCount = 0;
  }
  
  return root;
}