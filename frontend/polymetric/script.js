import { prepareData } from "./js/data.js";
import { buildHierarchy } from "./js/hierarchy.js";
import { setupFilters } from "./js/filters.js";
import { renderPolymetric } from "./js/polymetric.js";

let fileStructure = null;
let cloneData = null;

async function init(){
  try {
    // 1. Fetching two JSON files concurrently
    const [linesResponse, clonesResponse] = await Promise.all([
      fetch("lines.json"), 
      fetch("clones.json")
    ]);
    
    // Check for success responses
    if (!linesResponse.ok) {
        throw new Error(`Failed to load lines.json: ${linesResponse.status} ${linesResponse.statusText}`);
    }
    if (!clonesResponse.ok) {
        throw new Error(`Failed to load clones.json: ${clonesResponse.status} ${clonesResponse.statusText}`);
    }

    // 2. Parse JSON data
    fileStructure = await linesResponse.json();
    cloneData = await clonesResponse.json();
    
    // 3. Post-parse structure check (Crucial for the 'clones.clones' iterable error)
    if (!cloneData || !Array.isArray(cloneData.clones)) {
         throw new Error("clones.json loaded but is missing the expected 'clones' array structure.");
    }

    // 4. Prepare and Render
    prepareData(fileStructure, cloneData);

    const onChange = () => {
      // collect module filters (No change here)
      const moduleCheckboxes = document.querySelectorAll("#moduleList input[type=checkbox]");
      const moduleSet = new Set();
      moduleCheckboxes.forEach(cb=>{ if(cb.checked) moduleSet.add(cb.value); });

      // collect type filters and the new toggle
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

      // Pass the structure, filter sets, and the new toggle state
      const hierarchy = buildHierarchy(fileStructure, moduleSet, typeSet, includeNoClones);
      renderPolymetric(hierarchy);
    };

    setupFilters(fileStructure, onChange);
    // initial render
    onChange();

  } catch (error) {
    // Display error prominently to the user
    console.error("Initialization Error:", error);
    const chartWrap = document.getElementById("chartWrap");
    if (chartWrap) {
        chartWrap.innerHTML = `<h2 style="color: red; text-align: center;">Data Loading Error:</h2><p style="text-align: center;">${error.message}</p>`;
    }
  }
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
  renderPolymetric(hierarchy);
});