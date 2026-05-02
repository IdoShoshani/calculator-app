const expressionValue = document.getElementById("expression-value");
const resultValue = document.getElementById("result-value");
const requestPreview = document.getElementById("request-preview");
const rawApiLink = document.getElementById("raw-api-link");
const successPanel = document.getElementById("success-panel");
const errorPanel = document.getElementById("error-panel");
const healthBadge = document.getElementById("health-badge");

const OP_MAP = { "+": "add", "−": "subtract", "×": "multiply", "÷": "divide" };

let display = "0";
let firstOperand = null;
let pendingOp = null;
let waitingForSecond = false;
let justCalculated = false;

function formatNumber(n) {
  if (Number.isInteger(n)) return String(n);
  return String(parseFloat(n.toPrecision(10)));
}

function updateDisplay() {
  resultValue.textContent = display.length > 12
    ? parseFloat(display).toExponential(4)
    : display;
}

function setExpression(text) {
  expressionValue.textContent = text;
}

function showSuccess(msg) {
  successPanel.textContent = msg;
  successPanel.classList.remove("hidden");
  errorPanel.classList.add("hidden");
}

function showError(msg) {
  errorPanel.textContent = msg;
  errorPanel.classList.remove("hidden");
  successPanel.classList.add("hidden");
}

function clearStatus() {
  successPanel.classList.add("hidden");
  errorPanel.classList.add("hidden");
}

function setActiveOp(op) {
  document.querySelectorAll(".btn-op").forEach(b =>
    b.classList.toggle("active-op", b.dataset.op === op)
  );
}

function inputDigit(digit) {
  if (waitingForSecond) {
    display = digit;
    waitingForSecond = false;
  } else if (justCalculated) {
    display = digit;
    justCalculated = false;
    firstOperand = null;
    pendingOp = null;
    setExpression("");
    setActiveOp(null);
  } else {
    display = display === "0" ? digit : display + digit;
  }
  clearStatus();
  updateDisplay();
}

function inputDecimal() {
  if (waitingForSecond) {
    display = "0.";
    waitingForSecond = false;
    updateDisplay();
    return;
  }
  if (!display.includes(".")) {
    display += ".";
    updateDisplay();
  }
}

function inputBackspace() {
  if (justCalculated || display === "Error") return;
  display = display.length > 1 ? display.slice(0, -1) : "0";
  updateDisplay();
}

function clearAll() {
  display = "0";
  firstOperand = null;
  pendingOp = null;
  waitingForSecond = false;
  justCalculated = false;
  setExpression("");
  setActiveOp(null);
  requestPreview.textContent = "—";
  rawApiLink.href = "#";
  clearStatus();
  updateDisplay();
}

async function performCalculation(a, b, op) {
  const url = `/api/calculate/${OP_MAP[op]}?a=${a}&b=${b}`;
  requestPreview.textContent = `GET ${url}`;
  rawApiLink.href = url;
  try {
    const response = await fetch(url);
    const payload = await response.json();
    if (!response.ok) {
      showError(payload.error || "Error");
      display = "Error";
      firstOperand = null;
      pendingOp = null;
      waitingForSecond = false;
      justCalculated = true;
      setActiveOp(null);
      updateDisplay();
      return null;
    }
    showSuccess("OK");
    return payload.result;
  } catch {
    showError("API unreachable");
    display = "Error";
    updateDisplay();
    return null;
  }
}

async function inputOperator(op) {
  const current = parseFloat(display);
  if (firstOperand !== null && !waitingForSecond && !justCalculated) {
    const result = await performCalculation(firstOperand, current, pendingOp);
    if (result === null) return;
    firstOperand = result;
    display = formatNumber(result);
    updateDisplay();
  } else {
    firstOperand = parseFloat(display);
  }
  pendingOp = op;
  waitingForSecond = true;
  justCalculated = false;
  setExpression(`${formatNumber(firstOperand)} ${op}`);
  setActiveOp(op);
}

async function inputEquals() {
  if (firstOperand === null || pendingOp === null) return;
  const second = parseFloat(display);
  setExpression(`${formatNumber(firstOperand)} ${pendingOp} ${second} =`);
  const result = await performCalculation(firstOperand, second, pendingOp);
  if (result === null) return;
  display = formatNumber(result);
  firstOperand = result;
  pendingOp = null;
  waitingForSecond = false;
  justCalculated = true;
  setActiveOp(null);
  updateDisplay();
}

document.querySelector(".numpad").addEventListener("click", e => {
  const btn = e.target.closest("button");
  if (!btn) return;
  const { digit, op, action } = btn.dataset;
  if (digit !== undefined)        inputDigit(digit);
  else if (op)                    inputOperator(op);
  else if (action === "clear")    clearAll();
  else if (action === "backspace") inputBackspace();
  else if (action === "decimal")  inputDecimal();
  else if (action === "equals")   inputEquals();
});

document.addEventListener("keydown", e => {
  if (e.key >= "0" && e.key <= "9")          inputDigit(e.key);
  else if (e.key === ".")                     inputDecimal();
  else if (e.key === "+")                     inputOperator("+");
  else if (e.key === "-")                     inputOperator("−");
  else if (e.key === "*")                     inputOperator("×");
  else if (e.key === "/") { e.preventDefault(); inputOperator("÷"); }
  else if (e.key === "Enter" || e.key === "=") inputEquals();
  else if (e.key === "Backspace")             inputBackspace();
  else if (e.key === "Escape" || e.key.toLowerCase() === "c") clearAll();
});

async function checkHealth() {
  try {
    const response = await fetch("/actuator/health");
    const payload = await response.json();
    if (response.ok && payload.status === "UP") {
      healthBadge.textContent = "API healthy";
      healthBadge.className = "health-badge up";
      return;
    }
  } catch {}
  healthBadge.textContent = "API down";
  healthBadge.className = "health-badge down";
}

checkHealth();
