const godotClasses = [
  "Dialogue",
  "DialogueLabel",
  "Label",
  "Stage",

  "int",
  "float",
  "bool",
  "string",
  "Dictionary",
  "void",
]

function godotClassURL(n) {
  return `https://docs.godotengine.org/en/stable/classes/class_${n.toLowerCase()}.html`;
}

function createClassLink(className, classes="") {
  return `
  <a ${ !["Dialogue", "DialogueLabel", "Stage"].includes(className) ? `href="${godotClassURL(className)}"` : ''
  } class="${classes}" target="_blank">${className}</a>`;
}

function createParameter(param, arg) {
  return `<span class="params">${param}: ${createClassLink(arg)}</span>`;
}

document.querySelectorAll(".return").forEach(
  e => {
    let name = e.textContent;

    e.innerHTML = "";
    e.textContent = "";

    let returnType = "";

    e.classList.forEach(c => {
      if (godotClasses.includes(c)) {
        returnType = createClassLink(c);
        return;
      }
    })

    let params = "";

    if (e.classList.contains("func")) {
      params += "(";
      if (e.hasAttribute("params")) {
        e.getAttribute("params").split(" ").forEach(c => {
          let paramAttr = c.split("-");
          params += createParameter(paramAttr[0], paramAttr[1]);
        })
      }
      params += ")";
    }

    e.innerHTML = `
    ${returnType}<span class="keyword">${name}</span>${params}
    `
  }
);