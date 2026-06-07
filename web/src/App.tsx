import { useState } from "react";
import {
  WASI,
  File as WasiFile,
  OpenFile,
  ConsoleStdout,
  PreopenDirectory,
} from "@bjorn3/browser_wasi_shim";
import { Card, CardContent, CardHeader, CardTitle } from "./components/ui/card";
import { Label } from "./components/ui/label";
import { Alert, AlertDescription } from "./components/ui/alert";
import { Input } from "./components/ui/input";
import { Button } from "./components/ui/button";
import { ScrollArea } from "./components/ui/scroll-area";

type WasiInstance = WebAssembly.Instance & {
  exports: WebAssembly.Exports & {
    memory: WebAssembly.Memory;
    _start: () => unknown;
  };
};

type EngineName = "haskell" | "javascript";

type EngineResult = {
  name: string;
  output: string;
  elapsedMs: number;
  error?: string;
};

const encoder = new TextEncoder();

let wasmModulePromise: Promise<WebAssembly.Module> | null = null;

function loadWasmModule(): Promise<WebAssembly.Module> {
  if (!wasmModulePromise) {
    const wasmUrl = `${import.meta.env.BASE_URL}haskell-grep-lite.wasm`;

    wasmModulePromise = WebAssembly.compileStreaming(fetch(wasmUrl)).catch(
      async () => {
        const response = await fetch(wasmUrl);
        const bytes = await response.arrayBuffer();
        return WebAssembly.compile(bytes);
      },
    );
  }

  return wasmModulePromise;
}

function runJavaScriptRegex(pattern: string, inputText: string): string {
  const regex = new RegExp(pattern);

  return (
    inputText
      .split(/\r?\n/)
      .filter((line) => regex.test(line))
      .join("\n") + "\n"
  );
}

async function measureEngine(
  name: string,
  run: () => Promise<string> | string,
): Promise<EngineResult> {
  const startedAt = performance.now();

  try {
    const output = await run();
    const elapsedMs = performance.now() - startedAt;

    return {
      name,
      output: output || "No matches.",
      elapsedMs,
    };
  } catch (err) {
    const elapsedMs = performance.now() - startedAt;

    return {
      name,
      output: "",
      elapsedMs,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

async function runGrep(pattern: string, inputText: string): Promise<string> {
  let stdout = "";
  let stderr = "";

  const fds = [
    new OpenFile(new WasiFile([])),
    ConsoleStdout.lineBuffered((line) => {
      stdout += `${line}\n`;
    }),
    ConsoleStdout.lineBuffered((line) => {
      stderr += `${line}\n`;
    }),
    new PreopenDirectory(
      ".",
      new Map([["input.txt", new WasiFile(encoder.encode(inputText))]]),
    ),
  ];

  const wasi = new WASI(["haskell-grep-lite", pattern, "input.txt"], [], fds);

  const wasmModule = await loadWasmModule();

  const instance = await WebAssembly.instantiate(wasmModule, {
    wasi_snapshot_preview1: wasi.wasiImport,
  });

  wasi.start(instance as WasiInstance);

  return stderr.trim() === "" ? stdout : stderr;
}

export default function App() {
  const [pattern, setPattern] = useState("b");
  const [file, setFile] = useState<globalThis.File | null>(null);
  const [results, setResults] = useState<EngineResult[]>([]);
  const [isRunning, setIsRunning] = useState(false);
  const [error, setError] = useState("");

  async function handleRun() {
    const selectedFile = file;

    if (!selectedFile) {
      setError("Choose a file first.");
      setResults([]);
      return;
    }

    setIsRunning(true);
    setError("");
    setResults([]);

    try {
      const inputText = await selectedFile.text();

      const nextResults = await Promise.all([
        measureEngine("Haskell WASM", () => runGrep(pattern, inputText)),
        measureEngine("JavaScript RegExp", () =>
          runJavaScriptRegex(pattern, inputText),
        ),
      ]);

      setResults(nextResults);
    } catch (err) {
      setResults([]);
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setIsRunning(false);
    }
  }

  return (
    <main className="min-h-screen bg-background px-6 py-10 text-foreground">
      <div className="mx-auto grid max-w-3xl gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Haskell Grep Lite</CardTitle>
          </CardHeader>

          <CardContent className="grid gap-5">
            <div className="grid gap-2">
              <Label htmlFor="pattern">Pattern</Label>
              <Input
                id="pattern"
                value={pattern}
                onChange={(event) => setPattern(event.target.value)}
                placeholder="a|b"
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="input-file">Input file</Label>
              <Input
                id="input-file"
                type="file"
                accept=".txt,text/plain"
                onChange={(event) => {
                  setFile(event.target.files?.[0] ?? null);
                  setOutput("");
                  setError("");
                }}
              />
            </div>

            {file ? (
              <p className="text-sm text-muted-foreground">{file.name}</p>
            ) : null}

            {error ? (
              <Alert variant="destructive">
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            ) : null}

            <Button type="button" onClick={handleRun} disabled={isRunning}>
              {isRunning ? "Running..." : "Run"}
            </Button>
          </CardContent>
        </Card>

        <div className="grid gap-4 md:grid-cols-2">
          {results.map((result) => (
            <Card key={result.name}>
              <CardHeader>
                <CardTitle className="flex items-center justify-between gap-3">
                  <span>{result.name}</span>
                  <span className="text-sm font-normal text-muted-foreground">
                    {result.elapsedMs.toFixed(2)} ms
                  </span>
                </CardTitle>
              </CardHeader>

              <CardContent>
                {result.error ? (
                  <Alert variant="destructive">
                    <AlertDescription>{result.error}</AlertDescription>
                  </Alert>
                ) : (
                  <ScrollArea className="h-72 rounded-md border bg-muted/30">
                    <pre className="min-h-72 whitespace-pre-wrap p-4 font-mono text-sm">
                      {result.output}
                    </pre>
                  </ScrollArea>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </main>
  );
}
