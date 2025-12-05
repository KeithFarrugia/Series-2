/** Merge overlapping ranges array [{start,end},...] and return merged array */
export function mergeRanges(ranges){
  if(!ranges || ranges.length===0) return [];
  // (mergeRanges function body remains unchanged)
  const arr = ranges.map(r=>({start: r.start, end: r.end})).sort((a,b)=>a.start-b.start);
  const out = [arr[0]];
  for(let i=1;i<arr.length;i++){
    const cur = arr[i];
    const last = out[out.length-1];
    if(cur.start <= last.end + 1){
      last.end = Math.max(last.end, cur.end);
    } else {
      out.push(cur);
    }
  }
  return out;
}

/** Pre-processes file structure by collecting raw, unmerged clone ranges */
function prepareFileRawRanges(file, allClones){
  const cloneTypeRanges = { 'type1': [], 'type2': [], 'type3': [] };

  // Collect raw ranges and group them by type
  for(const cloneGroup of allClones.clones){
    const typeKey = `type${cloneGroup.cloneType}`;
    if (!cloneTypeRanges[typeKey]) continue;

    for(const loc of cloneGroup.locations){
      if(loc.filePath === file.filePath){
        if(typeof loc.startLine === "number" && typeof loc.endLine === "number"){
          // clamp into file bounds
          const start = Math.max(1, loc.startLine);
          const end = Math.min(file.linesOfCode || Infinity, loc.endLine);
          if(end >= start) {
            cloneTypeRanges[typeKey].push({ start, end });
          }
        }
      }
    }
  }

  // Store the raw range data by type for filtering and dynamic calculation
  file._rawCloneRanges = cloneTypeRanges;
}

/* ------------- Prepare data: only prepare raw ranges and project averages ------------- */
/** Merges clone information into the file structure and computes project averages. */
export function prepareData(fileStructure, cloneData){
  let totalLOC = 0;
  let totalFiles = 0;

  for(const module of fileStructure.modules){
    module.fileCount = module.files.length;
    for(const file of module.files){
      prepareFileRawRanges(file, cloneData);
      totalLOC += (file.linesOfCode || 0);
      totalFiles++;
    }
  }

  // Attach project-wide averages to the data root
  fileStructure.projectMetrics = {
    avgLOC: totalFiles > 0 ? totalLOC / totalFiles : 1,
    avgFileCount: fileStructure.modules.length > 0 ? totalFiles / fileStructure.modules.length : 1
  };
}

// NEW FUNCTION: Calculates metrics based on a specific filter set (Copied from previous fix)
export function calculateFilteredDuplication(file, typeFilterSet) {
    const allRanges = [];

    // 1. Collect ranges only from the types present in the filter set
    for (const t of typeFilterSet) { // t is like 'type1', 'type2', etc.
        if (file._rawCloneRanges && file._rawCloneRanges[t]) {
            allRanges.push(...file._rawCloneRanges[t]);
        }
    }

    // 2. Compute merged duplicated lines and percentage
    const merged = mergeRanges(allRanges);
    let duplicatedLines = 0;
    for(const r of merged) duplicatedLines += (r.end - r.start + 1);

    const loc = file.linesOfCode || 0;
    // Round to 1 decimal place
    const duplicationPercent = loc > 0 ? Math.round((duplicatedLines / loc) * 1000) / 10 : 0;

    return {
        duplicatedLines,
        duplicationPercent,
        mergedRanges: merged
    };
}