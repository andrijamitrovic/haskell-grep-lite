import {
  WASI,
  File,
  OpenFile,
  ConsoleStdout,
  PreopenDirectory
} from "https://cdn.jsdelivr.net/npm/@bjorn3/browser_wasi_shim@0.4.2/+esm";

const encoder = new TextEncoder();

const patternInput = document.querySelector("#pattern");
const textInput = document.querySelector("#input");
const output = document.querySelector("#output");
const runButton = document.querySelector("#run");

async function runGrep(pattern, inputText) {
  let stdout = "";
  let stderr = "";

  const fds = [
    new OpenFile(new File([])),
    ConsoleStdout.lineBuffered((line) => {
      stdout += line + "\n";
    }),
    ConsoleStdout.lineBuffered((line) => {
      stderr += line + "\n";
    }),
    new PreopenDirectory(".", [
      ["input.txt", new File(encoder.encode(inputText))]
    ])
  ];

  const wasi = new WASI(
    ["haskell-grep-lite", pattern, "input.txt"],
    [],
    fds
  );

  const wasm = await WebAssembly.compileStreaming(
    fetch("./haskell-grep-lite.wasm")
  );

  const instance = await WebAssembly.instantiate(wasm, {
    wasi_snapshot_preview1: wasi.wasiImport
  });

  wasi.start(instance);

  if (stderr.trim() !== "") {
    return stderr;
  }

  return stdout;
}

runButton.addEventListener("click", async () => {
  output.textContent = "Running...";

  try {
    output.textContent = await runGrep(
      patternInput.value,
      textInput.value
    );
  } catch (err) {
    output.textContent = String(err);
  }
});