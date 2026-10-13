# Static configuration check: render the OpenCode global config template
# with the fleet default data (`.chezmoidata/defaults.toml`) and validate
# the result parses as JSONC with a sane number of MCP servers.
#
# This is the fast, hermetic sibling of `sys-check`'s config check —
# it runs in `nix flake check` without booting a VM.
{ pkgs, self }:

pkgs.runCommand "opencode-config-check"
  {
    nativeBuildInputs = with pkgs; [ chezmoi nodejs ];
  }
  ''
    export HOME=$TMPDIR/home
    mkdir -p "$HOME" "$out" src/.chezmoidata src/opencode
    install -m644 ${self}/.chezmoidata/defaults.toml src/.chezmoidata/defaults.toml
    install -m644 ${self}/private_dot_config/opencode/private_opencode.jsonc.tmpl src/opencode/config.tmpl

    chezmoi execute-template --source "$PWD/src" < src/opencode/config.tmpl > rendered.jsonc

    cat > strip.js <<'EOF'
const fs = require("fs");
let s = fs.readFileSync(process.argv[2], "utf8"), o = "", inStr = false, inCmt = false;
for (let i = 0; i < s.length; i++) {
  const c = s[i], n = s[i + 1];
  if (inCmt) { if (c === "\n") { inCmt = false; o += c; } continue; }
  if (inStr) { o += c; if (c === "\"" && s[i - 1] !== "\\") inStr = false; continue; }
  if (c === "\"") { inStr = true; o += c; continue; }
  if (c === "/" && n === "/") { inCmt = true; continue; }
  o += c;
}
const cfg = JSON.parse(o);
const servers = Object.keys(cfg.mcp.servers);
if (servers.length < 5) throw new Error("too few MCP servers rendered: " + servers.join(","));
if (!cfg.mcp.servers.ghidra || !cfg.mcp.servers.radare2) throw new Error("RE servers missing");
console.log("opencode config ok: " + servers.join(","));
EOF
    node strip.js rendered.jsonc | tee $out/servers.txt
  ''
