import { prepareData } from "./js/data.js";
import { buildHierarchy } from "./js/hierarchy.js";
import { setupFilters } from "./js/filters.js";
import { renderTreemap } from "./js/treemap.js";

let data = null;
async function init(){
  data = await fetch("clones.json").then(r => r.json());
  prepareData(data);

  const onChange = () => {
    // collect module filters
    const moduleCheckboxes = document.querySelectorAll("#moduleList input[type=checkbox]");
    const moduleSet = new Set();
    moduleCheckboxes.forEach(cb=>{ if(cb.checked) moduleSet.add(cb.value); });

    // collect type filters
    const typeCheckboxes = document.querySelectorAll("#typeList input[type=checkbox]");
    const typeSet = new Set();
    typeCheckboxes.forEach(cb=>{ if(cb.checked) typeSet.add(cb.value); });

    const hierarchy = buildHierarchy(data, moduleSet, typeSet);
    renderTreemap(hierarchy);
  };

  setupFilters(data, onChange);
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
  const hierarchy = buildHierarchy(data, moduleSet, typeSet);
  renderTreemap(hierarchy);
});