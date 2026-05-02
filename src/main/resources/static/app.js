const form = document.getElementById("calculator-form");
const operationButtons = Array.from(document.querySelectorAll(".operation-button"));
const inputA = document.getElementById("input-a");
const inputB = document.getElementById("input-b");
const expressionValue = document.getElementById("expression-value");
const resultValue = document.getElementById("result-value");
const requestPreview = document.getElementById("request-preview");
const rawApiLink = document.getElementById("raw-api-link");
const successPanel = document.getElementById("success-panel");
const errorPanel = document.getElementById("error-panel");
const healthBadge = document.getElementById("health-badge");
const swapButton = document.getElementById("swap-button");

let currentOperation = "add";
let currentSymbol = "+";

function buildRequestUrl() {
  const a = inputA.value.trim();
  const b = inputB.value.trim();
  return `/api/calculate/${currentOperation}?a=${encodeURIComponent(a)}&b=${encodeURIComponent(b)}`;
}

function refreshUiText() {
  const requestUrl = buildRequestUrl();
  expressionValue.textContent = `${inputA.value || "?"} ${currentSymbol} ${inputB.value || "?"}`;
  requestPreview.textContent = `GET ${requestUrl}`;
  rawApiLink.href = requestUrl;
}

function setOperation(button) {
  currentOperation = button.dataset.operation;
  currentSymbol = button.dataset.symbol;

  for (const operationButton of operationButtons) {
    operationButton.classList.toggle("active", operationButton === button);
  }

  refreshUiText();
}

function showSuccess(message) {
  successPanel.textContent = message;
  successPanel.classList.remove("hidden");
  errorPanel.classList.add("hidden");
}

function showError(message) {
  errorPanel.textContent = message;
  errorPanel.classList.remove("hidden");
  successPanel.classList.add("hidden");
}

async function checkHealth() {
  try {
    const response = await fetch("/actuator/health");
    const payload = await response.json();

    if (response.ok && payload.status === "UP") {
      healthBadge.textContent = "API healthy";
      healthBadge.className = "health-badge up";
      return;
    }
  } catch (error) {
    // The UI still works enough to show the connection error below.
  }

  healthBadge.textContent = "API down";
  healthBadge.className = "health-badge down";
}

async function calculate(event) {
  event.preventDefault();
  refreshUiText();

  try {
    const response = await fetch(buildRequestUrl());
    const payload = await response.json();

    if (!response.ok) {
      showError(payload.error || "Calculation failed");
      return;
    }

    resultValue.textContent = payload.result;
    showSuccess("OK");
  } catch (error) {
    showError("API request failed");
  }
}

for (const button of operationButtons) {
  button.addEventListener("click", () => setOperation(button));
}

swapButton.addEventListener("click", () => {
  const nextA = inputB.value;
  inputB.value = inputA.value;
  inputA.value = nextA;
  refreshUiText();
});

inputA.addEventListener("input", refreshUiText);
inputB.addEventListener("input", refreshUiText);
form.addEventListener("submit", calculate);

refreshUiText();
checkHealth();
