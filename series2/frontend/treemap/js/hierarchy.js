import { calculateFilteredDuplication } from "./data.js"; // Import the new function

/* ------------- Build D3 hierarchy (modules -> files). value = linesOfCode ------------- */
export function buildHierarchy(data, moduleFilterSet, typeFilterSet, includeNoClones){
  // data is the file structure merged with raw clone ranges
  const root = { name: data.projectRoot, children: [] };
  const allCloneTypes = ['type1', 'type2', 'type3']; // Used for checking if a file has any clones

  // Fallback: If no type filters are active, treat it as "show all"
  const activeTypeFilterSet = typeFilterSet.size > 0 ? typeFilterSet : new Set(allCloneTypes);

  for(const mod of data.modules){
    if(moduleFilterSet.size && !moduleFilterSet.has(mod.name)) continue;

    const modNode = { name: mod.name, children: [] };
    for(const file of mod.files){
      
      // Calculate the metrics based only on the active type filters
      const filteredMetrics = calculateFilteredDuplication(file, activeTypeFilterSet);
      
      let passesFilter = true;
      
      // Filtering Logic: Exclude files that have 0% duplication for the filtered type set
      if (typeFilterSet.size > 0 && !includeNoClones && filteredMetrics.duplicatedLines === 0) {
          passesFilter = false;
      }
      // IMPORTANT EXCEPTION: If the user has no filters selected, we use the 
      // default metric (which is calculated above by `activeTypeFilterSet`), 
      // and we always include all files for the initial view.
      if (typeFilterSet.size === 0) {
          passesFilter = true; 
      }

      if(!passesFilter) continue; // Exclude file

      // leaf node
      modNode.children.push({
        name: file.name,
        filePath: file.filePath,
        linesOfCode: file.linesOfCode || 0,
        duplicationPercent: filteredMetrics.duplicationPercent,
        duplicatedLines: filteredMetrics.duplicatedLines,
        mergedRanges: filteredMetrics.mergedRanges,
      });
    }

    // only add module if it has children after filtering
    if(modNode.children.length>0) root.children.push(modNode);
  }

  return root;
}