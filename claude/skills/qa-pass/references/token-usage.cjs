// Token usage per model, day, and main vs subagent from Claude Code transcripts.
// Usage: node token-usage.cjs [project-folder-name]   (default: the sekira project)
// Read-only; prints counts only, never transcript text. One record per API message
// (the max of each counter across its stream records), so nothing is counted twice.
// Dollar cost is deliberately not computed: apply the published rate card to the
// per-model counters, and note whether the plan is billed per token.
const fs = require("fs");
const path = require("path");
const readline = require("readline");

const ROOT = path.join(require("os").homedir(), ".claude", "projects", process.argv[2] ?? "C--Users-aminr-workspaces-sekira");
const KEYS = ["input_tokens", "output_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"];

function* walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (e.name === "tool-results") continue;
      yield* walk(p);
    } else if (e.name.endsWith(".jsonl")) yield p;
  }
}

const msgs = new Map();
let files = 0;

async function main() {
  for (const f of walk(ROOT)) {
    files++;
    const kind = f.split(path.sep).join("/").includes("/subagents/") ? "subagent" : "main";
    const rl = readline.createInterface({ input: fs.createReadStream(f), crlfDelay: Infinity });
    for await (const line of rl) {
      if (!line.includes('"usage"')) continue;
      let j;
      try {
        j = JSON.parse(line);
      } catch {
        continue;
      }
      const m = j.message;
      if (!m || !m.usage || m.model === "<synthetic>") continue;
      const id = m.id ?? j.uuid;
      let rec = msgs.get(id);
      if (!rec) {
        rec = { model: m.model ?? "unknown", day: (j.timestamp ?? "").slice(0, 10), kind, u: {} };
        msgs.set(id, rec);
      }
      for (const k of KEYS) rec.u[k] = Math.max(rec.u[k] ?? 0, m.usage[k] ?? 0);
    }
  }

  const zero = () => ({ calls: 0, input: 0, output: 0, cw: 0, cr: 0 });
  const byModel = {};
  const byDay = {};
  const byKind = { main: zero(), subagent: zero() };
  const total = zero();
  const add = (o, rec) => {
    o.calls++;
    o.input += rec.u.input_tokens ?? 0;
    o.output += rec.u.output_tokens ?? 0;
    o.cw += rec.u.cache_creation_input_tokens ?? 0;
    o.cr += rec.u.cache_read_input_tokens ?? 0;
  };
  for (const rec of msgs.values()) {
    add((byModel[rec.model] ??= zero()), rec);
    add((byDay[rec.day] ??= zero()), rec);
    add(byKind[rec.kind], rec);
    add(total, rec);
  }
  const n = (x) => x.toLocaleString("en-US");
  const row = (v) => `calls ${n(v.calls)} | input ${n(v.input)} | output ${n(v.output)} | cache write ${n(v.cw)} | cache read ${n(v.cr)}`;
  console.log(`files ${files}, unique API messages ${n(msgs.size)}`);
  console.log("TOTAL  " + row(total));
  console.log("\nBY MODEL");
  for (const [k, v] of Object.entries(byModel).sort((a, b) => b[1].output - a[1].output)) console.log(k + "\n  " + row(v));
  console.log("\nMAIN vs SUBAGENT");
  for (const [k, v] of Object.entries(byKind)) console.log(k + "  " + row(v));
  console.log("\nDAYS with data: " + Object.keys(byDay).filter((d) => d !== "").sort().join(" "));
  console.log("\nBUSIEST DAYS by output");
  for (const [k, v] of Object.entries(byDay).sort((a, b) => b[1].output - a[1].output).slice(0, 5)) console.log(k + "  " + row(v));
}
main();
