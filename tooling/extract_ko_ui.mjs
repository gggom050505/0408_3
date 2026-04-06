import { readFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const t = readFileSync(
  join(dirname(fileURLToPath(import.meta.url)), "web_chunk.js"),
  "utf8",
);
// 한글 연속 구간 (UI 문구 후보)
const re = /[\uAC00-\uD7A3][\uAC00-\uD7A3\s\d~.,!?·\-:;%℃＂＇"'「」\[\]()]+[\uAC00-\uD7A3]/g;
const seen = new Set();
for (const m of t.matchAll(re)) {
  const s = m[0].trim();
  if (s.length >= 4 && s.length < 80) seen.add(s);
}
[...seen].sort().forEach((s) => console.log(s));
