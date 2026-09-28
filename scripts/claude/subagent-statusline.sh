#!/usr/bin/env bash
# Claude Code subagent rows. Payload schema: https://code.claude.com/docs/en/statusline#subagent-status-lines
#
#   ● Explore  find statusline refs · haiku-4-5 · ▰▰▱▱▱ 36% 72k/200k · 1m12s
#
# Prints one {"id","content"} JSON line per task; tasks left out keep the
# default rendering, so any failure here degrades to Claude Code's own rows.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

jq -c --argjson now "$(date +%s)" '
  def esc: "\u001b[";
  def c($n): esc + "38;5;\($n)m";
  def reset: esc + "0m";
  def dim: c(244);

  def heat($p): if $p >= 80 then c(203) elif $p >= 50 then c(221) else c(114) end;

  def tok:
    if . >= 1000000 then "\(. / 100000 | floor / 10)M" | sub("\\.0M$"; "M")
    elif . >= 1000 then "\(. / 1000 | floor)k"
    else tostring end;

  def dur:
    (if . < 0 then 0 else . end) as $t
    | if   $t >= 3600 then "\($t / 3600 | floor)h\($t % 3600 / 60 | floor)m"
      elif $t >= 60   then "\($t / 60 | floor)m\($t % 60)s"
      else "\($t)s" end;

  # claude-haiku-4-5-20251001 -> haiku-4-5
  def short_model: sub("^claude-"; "") | sub("-[0-9]{8}$"; "") | sub("\\[.*\\]$"; "");

  (.columns // 120) as $cols
  | .tasks[]? | select(.id)
  | . as $t
  | ($t.status // "" | ascii_downcase) as $st
  | (if   ($st | test("run|progress|pending|start")) then c(221) + "●"
     elif ($st | test("complete|done|success"))     then c(114) + "✓"
     elif ($st | test("fail|error|kill|cancel|stop")) then c(203) + "✗"
     else dim + "○" end) as $icon

  # Everything after the description, as [plain text, coloured text] pairs so
  # the width budget is measured without escape codes.
  | ([ (if $t.model then
          [ ($t.model | short_model) + (if $t.effort then " \($t.effort)" else "" end) ]
          | [.[0], dim + .[0] + reset]
        else empty end),
       (if ($t.tokenCount and $t.contextWindowSize and $t.contextWindowSize > 0) then
          ($t.tokenCount * 100 / $t.contextWindowSize | floor) as $p
          | ([range(5)] | map(if . < (($p + 10) / 20 | floor) then "▰" else "▱" end) | join("")) as $bar
          | "\($p)% \($t.tokenCount | tok)/\($t.contextWindowSize | tok)" as $txt
          | [$bar + " " + $txt, heat($p) + $bar + " \($p)%" + reset + dim + " \($t.tokenCount | tok)/\($t.contextWindowSize | tok)" + reset]
        elif $t.tokenCount then
          [($t.tokenCount | tok) + " tok", dim + ($t.tokenCount | tok) + " tok" + reset]
        else empty end),
       (if $t.startTime then
          # startTime may be epoch ms or s.
          (($now - (if $t.startTime > 100000000000 then $t.startTime / 1000 else $t.startTime end)) | floor | dur) as $d
          | [$d, dim + $d + reset]
        else empty end)
     ]) as $tail

  | ($t.name // $t.label // $t.type // "agent") as $name
  | ($tail | map(.[0]) | join(" · ")) as $tail_plain
  | ($tail | map(.[1]) | join(dim + " · " + reset)) as $tail_col

  # Trim the description to whatever width is left.
  | ($cols - ($name | length) - ($tail_plain | length) - 9) as $room
  | ($t.description // "" | gsub("\\s+"; " ")) as $desc
  | (if $room < 4 or $desc == "" then ""
     elif ($desc | length) > $room then $desc[0:$room - 1] + "…"
     else $desc end) as $desc

  | { id: $t.id,
      content: ($icon + reset + " " + c(111) + $name + reset
                + (if $desc != "" then "  " + $desc else "" end)
                + (if $tail_col != "" then dim + " · " + reset + $tail_col else "" end)) }
' 2>/dev/null || true
