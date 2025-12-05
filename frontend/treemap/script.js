// script.js (updated fetch logic)
import { prepareData } from "./js/data.js";
import { buildHierarchy } from "./js/hierarchy.js";
import { setupFilters } from "./js/filters.js";
import { renderTreemap } from "./js/treemap.js";

let fileStructure = null; // Renamed 'data' to 'fileStructure' for clarity
let cloneData = null;

async function init(){
  // Fetching two JSON files concurrently
  const [linesResponse, clonesResponse] = await Promise.all([
    fetch("lines.json"), // Assuming lines.json contains the structure/LOC
    fetch("clones.json")
  ]);

  fileStructure = await linesResponse.json();
  cloneData = await clonesResponse.json();

  // Pass both to prepareData
  prepareData(fileStructure, cloneData);

  const onChange = () => {
    // collect module filters
    const moduleCheckboxes = document.querySelectorAll("#moduleList input[type=checkbox]");
    const moduleSet = new Set();
    moduleCheckboxes.forEach(cb=>{ if(cb.checked) moduleSet.add(cb.value); });

    // collect type filters
    const typeCheckboxes = document.querySelectorAll("#typeList input[type=checkbox]");
    const typeSet = new Set();
    let includeNoClones = false;
        
        typeCheckboxes.forEach(cb=>{ 
            if (cb.id === "includeNoClones") {
                // Read the state of the toggle checkbox
                includeNoClones = cb.checked;
            } else if (cb.checked) {
                // Collect the active clone types
                typeSet.add(cb.value); 
            }
        }); 

    const hierarchy = buildHierarchy(fileStructure, moduleSet, typeSet, includeNoClones);
    renderTreemap(hierarchy);
  };

  setupFilters(fileStructure, onChange); // pass fileStructure (which has modules/files)
  // initial render
  onChange();
}

window.addEventListener("load", init);
window.addEventListener("resize", ()=> {
  // simple redraw on resize
  const moduleCheckboxes = document.querySelectorAll("#moduleList input[type=checkbox]");
  const moduleSet = new Set();
  moduleCheckboxes.forEach(cb=>{ if(cb.checked) moduleSet.add(cb.value); });
  const typeCheckboxes = document.querySelectorAll("#typeList input[type=checkbox]");
  const typeSet = new Set();
  typeCheckboxes.forEach(cb=>{ if(cb.checked) typeSet.add(cb.value); });
  const hierarchy = buildHierarchy(fileStructure, moduleSet, typeSet);
  renderTreemap(hierarchy);
});