# Definitions over a transcript read with `jq -s` (an array of records).
# Used through `include "replay" {search: "<this directory>"};`, so that a
# replay.jq in the caller's working directory is never found first.
# replay.sh uses first_message_text, first_user_content, session_events and
# replay_log; rex-run.sh uses owner_messages. segments and pairs are not used
# by either script: the tests read them, and corpus.jq keeps copies of the
# shared definitions (check-corpus.sh keeps them equal).

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

# The text typed to start the session: the command name, a space and the
# command args (greedy up to the last closing tag); a plain first message
# is typed as it is.
def first_message_text:
  first_user_content
  | if contains("<command-name>")
    then (capture("<command-name>(?<name>[^<]*)</command-name>").name)
         + " "
         + (capture("<command-args>(?<args>[\\s\\S]*)</command-args>").args)
    else . end;

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

# Events of the session's own transcript, in file order, one object each:
# {kind: "first", content} (the first user record), {kind: "owner", content, uuid},
# {kind: "assistant", text}, {kind: "turn_end"}, {kind: "exit"}.
def session_events:
  first_user_index as $first
  | to_entries[] | .key as $k | .value
  | if $k == $first then {kind: "first", content: .message.content}
    elif .type == "user" and (.message.content | type) == "string"
         and (.message.content | contains("<command-name>/exit</command-name>"))
    then {kind: "exit"}
    elif is_owner_record then {kind: "owner", content: owner_text, uuid: .uuid}
    elif .type == "system" and .subtype == "turn_duration" then {kind: "turn_end"}
    else (assistant_text | select(. != null) | {kind: "assistant", text: .})
    end;

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

# Every segment of the recorded owner messages: id "<pair uuid>#<index>",
# label, segment and the session turn the message answered.
def segments:
  [pairs[] | . as $p
   | ($p.message | segments_of) | to_entries[]
   | {id: ($p.id + "#" + (.key | tostring)), label: .value.label,
      segment: .value.segment, session_turn: $p.turn}];

# One line per owner message on the transcript's final chain, in order: the
# message is "replayed" with its segment ids when its record's uuid is one of
# the uuids in $typed ([{text, segments, from, uuid}], one per typed answer), else
# "owner". A typed answer whose record is not on the chain is not logged.
def replay_log($typed):
  [owner_messages[]] as $records
  | [range(0; $records | length) as $k
     | ($records[$k].uuid) as $u
     | ([$typed[] | select(.uuid == $u)][0]) as $t
     | if $t != null
       then {n: ($k + 1), source: "replayed", segments: $t.segments, from: $t.from}
       else {n: ($k + 1), source: "owner"}
       end];
