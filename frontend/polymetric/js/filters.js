export function setupFilters(data, onChange){
  const moduleList = document.getElementById("moduleList");
  moduleList.innerHTML = "";

  // build module checkboxes
  for(const mod of data.modules){
    const label = document.createElement("label");
    label.innerHTML = `<input type="checkbox" value="${mod.name}" checked /> ${mod.name}`;
    moduleList.appendChild(label);
  }

  // attach change listeners
  moduleList.querySelectorAll("input[type=checkbox]").forEach(cb=>{
    cb.addEventListener("change", onChange);
  });

  // type checkboxes
  const typeList = document.getElementById("typeList");
  typeList.querySelectorAll("input[type=checkbox]").forEach(cb=>{
    cb.addEventListener("change", onChange);
  });
}