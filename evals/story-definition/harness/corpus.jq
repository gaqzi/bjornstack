# Definitions for the corpus of a spec: every answer the owner has given
# runs of the same spec, and the clashes between them. Used through
# `include "corpus" {search: "<this directory>"};`, so that a corpus.jq in
# the caller's working directory is never found first.
#
# The first block is copied from replay.jq, not included from it: jq 1.8.2
# aborts ("Unknown function type") when a function of a module included by
# this one calls another function of that module. Keep the copies equal to
# replay.jq's.

# The first user record: the first message typed into the session, not an
# owner message.
def first_user_index: [to_entries[] | select(.value.type == "user") | .key][0];

# The recorded transcript as the session ended: the last record with a uuid
# that is not a sidechain one, and its ancestors, in file order. An ancestor
# is the parentUuid record, or the logicalParentUuid record where parentUuid
# is null (a compaction boundary). A rewound sibling is not on that chain.
def final_chain:
  . as $all
  | ([.[] | select(.uuid != null and .isSidechain != true)] | last) as $leaf
  | if $leaf == null then []
    else
      (reduce $all[] as $r ({}; if $r.uuid != null then .[$r.uuid] = $r else . end)) as $by
      | ([$leaf | recurse((.parentUuid // .logicalParentUuid) as $p
                          | if $p != null and $by[$p] != null
                          then $by[$p] else empty end) | .uuid]
         | reduce .[] as $u ({}; .[$u] = true)) as $on
      | [$all[] | select(.uuid != null and $on[.uuid] == true)]
    end;

# What the owner typed in a record, or null when it is not an owner message:
# a user record with string content that is not a meta record, not a
# compaction summary (isCompactSummary) and not a command record, or a message
# typed while a turn ran (a queued_command attachment from a human).
def owner_text:
  if .type == "user"
     and (.message.content | type) == "string"
     and .isMeta != true
     and .isCompactSummary != true
     and (.message.content
          | startswith("<command-message>") or startswith("<command-name>") or startswith("<local-command")
          | not)
  then .message.content
  elif .type == "attachment"
       and .attachment.type == "queued_command"
       and .attachment.origin.kind == "human"
       and (.attachment.prompt | type) == "string"
  then .attachment.prompt
  else null end;

def is_owner_record: owner_text != null;

# Owner records on the final chain (see final_chain), in file order, other
# than the first user record.
def owner_messages:
  final_chain
  | first_user_index as $first
  | [to_entries[] | select(.key != $first) | .value | select(is_owner_record)];

# The content of the first user record on the final chain.
def first_user_content:
  final_chain | .[first_user_index].message.content;

# The text blocks of an assistant record (not a sidechain one) joined with
# a blank line; null when it has none or the record is another kind.
def assistant_text:
  if .type == "assistant" and .isSidechain != true
  then [.message.content[]? | select(.type == "text") | .text]
       | if length > 0 then join("\n\n") else null end
  else null end;

# Recorded pairs: each owner message with the assistant text since the
# previous owner message (or the start).
def pairs:
  final_chain
  | first_user_index as $first
  | reduce to_entries[] as $e ({turn: [], out: []};
      if $e.key == $first then .
      elif ($e.value | is_owner_record) then
        .out += [{id: $e.value.uuid, turn: (.turn | join("\n\n")), message: ($e.value | owner_text)}]
        | .turn = []
      else
        ($e.value | assistant_text) as $t
        | if $t != null then .turn += [$t] else . end
      end)
  | .out;

# The segments of one owner message text, in order, as {label, segment}. A
# numbered line (digits, then : . or ) and a next character that is not a
# digit, so "10:30 ..." and "3.5 hours" are not numbered) is a segment
# labelled with its digits; the label and the spaces after it are removed
# from the segment. A word or a letter before a colon is not a label. A blank
# line ends a segment. A line that is not labelled continues the open
# segment, else starts a paragraph (label null).
def segments_of:
  reduce split("\n")[] as $line ({out: [], open: false};
    if ($line | test("^\\s*$")) then .open = false
    elif ($line | test("^[0-9]+[:.)]([^0-9]|$)")) then
      ($line | capture("^(?<l>[0-9]+)[:.)] *(?<t>.*)$")) as $m
      | .out += [{label: $m.l, segment: $m.t}] | .open = true
    elif .open then .out[-1].segment += "\n" + $line
    else .out += [{label: null, segment: $line}] | .open = true
    end)
  | .out;

def trim_end: sub("\\s+$"; "");

# A spec text as written down: trailing whitespace, then the owner-away line
# rex-run.sh may add, then the whitespace before it, removed.
def normalise_spec:
  trim_end
  | sub("\n\nThe owner is away for this session$"; "")
  | trim_end;

# Over a transcript array: the spec the run was started with (the command
# args of the first user record, or the plain first message); null when the
# transcript has no user record on the final chain.
def spec_text:
  if (final_chain | first_user_index) == null then null
  else
    first_user_content
    | if contains("<command-name>")
      then capture("<command-args>(?<args>[\\s\\S]*)</command-args>").args
      else . end
    | normalise_spec
  end;

# Over the raw text of prompt.txt (a headless run has no user record): the
# text after the story-definition command; null for any other prompt.
def spec_of_prompt:
  "/bjornstack:story-definition " as $cmd
  | if startswith($cmd) then .[$cmd | length:] | normalise_spec else null end;

# Over a transcript array: the owner's answers as segments, one per numbered
# line or paragraph of each owner message, {id, label, segment, session_turn,
# run, record, order}; order is the position of the record among the run's
# owner messages on the final chain, from 1 (a copy keeps its place). $log is
# the lines of replay.jsonl (or null for a live run): with it only the owner
# messages logged "owner" count, a "replayed" one is a copy of an answer
# already in the corpus as another run's.
def owner_segments($run; $log):
  [pairs | to_entries[]
   | (.key + 1) as $n | .value as $p
   | select($log == null or ([$log[] | select(.n == $n)][0].source == "owner"))
   | ($p.message | segments_of) | to_entries[]
   | {id: ($p.id + "#" + (.key | tostring)), label: .value.label,
      segment: .value.segment, session_turn: $p.turn, run: $run, record: $p.id,
      order: $n}];

# Over null: $segments without every id the owner has dropped when settling.
# $settled is the lines of settled.jsonl, oldest first; a line may lack keep
# or lack drop. The latest line that names an id (as keep or in drop) decides
# it: dropped when it names it in drop, so a later keep revives it.
def effective($segments; $settled):
  (reduce $settled[] as $line ({};
     reduce ($line.drop // [])[] as $id (.; .[$id] = true)
     | if $line.keep != null then .[$line.keep] = false else . end)) as $dropped
  | [$segments[] | select($dropped[.id] != true)];

# Over null: $met (the clashes met during a replay), each cleaned against
# $segments (an id that is not one is removed, a clash left with fewer than
# two ids is removed); one clash per id set, the first.
def merge_clashes($met; $segments):
  [$segments[].id] as $known
  | reduce ($met[]
            | .answers |= [.[] | select(. as $a | $known | index($a))]
            | select(.answers | length >= 2)) as $c
      ([];
       if any(.[]; (.answers | sort) == ($c.answers | sort)) then . else . + [$c] end);

# Over null: what `corpus.sh clashes` prints for the owner, one block per clash: the
# question, each answer with its run and record, and one settle line per
# answer, keeping it and dropping the others.
def clash_listing($clashes; $segments):
  [$clashes[]
   | .answers as $ids
   | "clash: \(.question)\n"
     + ([$ids[] as $id | ([$segments[] | select(.id == $id)][0]) as $s
         | "  answer \($id): \($s.segment)\n    run \($s.run), record \($s.record)"] | join("\n"))
     + "\n"
     + ([$ids[] as $id | "  settle with: --keep \($id) --drop \([$ids[] | select(. != $id)] | join(" "))"] | join("\n"))]
  | join("\n\n");
