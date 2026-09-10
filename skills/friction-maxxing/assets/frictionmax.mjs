#!/usr/bin/env node
// friction-maxxing hook.
//
// Wired into Claude Code, Codex and Gemini CLI. All three share one hook protocol:
//   stdin  <- JSON event payload
//   stdout -> {"hookSpecificOutput":{"hookEventName":"...","additionalContext":"..."}}
//
// Two jobs, both mechanical:
//   1. Inject the mandate once per session, and a cheap one-line re-arm every Nth turn.
//      The mandate is sent on the first PER-TURN event rather than only at SessionStart,
//      because SessionStart delivery is not uniform across agents and run modes (verified
//      reaching context in Codex; `claude -p` print mode does not run these hooks at all).
//      Sending it on turn one costs a possible duplicate; relying on SessionStart alone
//      risks it never landing.
//   2. Track the override phrases across a session so the gate stays down without the
//      model having to remember that it was told to stand down.
//
// It deliberately does NOT try to classify whether a prompt is a scope/voice decision.
// Those categories are semantic; no regex detects them. The model classifies, this injects.
//
// Absolute rule: this must never break or slow a session. Every failure path exits 0 silently.

import {
  readFileSync, writeFileSync, appendFileSync, mkdirSync, readdirSync, statSync, unlinkSync,
} from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';

const HERE = dirname(fileURLToPath(import.meta.url));
const STATE_DIR = join(tmpdir(), 'frictionmax');
const REARM_EVERY = 6;        // turns between one-line re-arms
const STALE_MS = 7 * 24 * 60 * 60 * 1000;

const SESSION_START = new Set(['SessionStart']);
const PER_TURN = new Set(['UserPromptSubmit', 'BeforeAgent', 'BeforeModel']);

// ---------------------------------------------------------------- payload

function readStdin() {
  try {
    return readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

// Each agent spells these slightly differently; accept every shape we have seen.
function pick(obj, ...keys) {
  for (const k of keys) {
    const v = obj?.[k];
    if (typeof v === 'string' && v.length) return v;
  }
  return '';
}

function eventNameOf(p) {
  return pick(p, 'hook_event_name', 'hookEventName', 'event_name', 'eventName', 'event');
}

function sessionIdOf(p) {
  return (
    pick(p, 'session_id', 'sessionId', 'conversation_id', 'conversationId', 'thread_id') ||
    'default'
  );
}

function promptOf(p) {
  return (
    pick(p, 'prompt', 'user_prompt', 'userPrompt', 'message', 'text', 'input') ||
    pick(p?.payload ?? {}, 'prompt', 'user_prompt', 'message', 'text')
  );
}

// ---------------------------------------------------------------- state

function statePath(sessionId) {
  const safe = String(sessionId).replace(/[^A-Za-z0-9._-]/g, '_').slice(0, 120);
  return join(STATE_DIR, `${safe}.json`);
}

function loadState(sessionId) {
  try {
    return JSON.parse(readFileSync(statePath(sessionId), 'utf8'));
  } catch {
    return { armed: true, turn: 0 };
  }
}

function saveState(sessionId, state) {
  try {
    mkdirSync(STATE_DIR, { recursive: true });
    writeFileSync(statePath(sessionId), JSON.stringify(state), 'utf8');
  } catch {
    /* state is a convenience, not a requirement */
  }
}

function sweepStale() {
  try {
    const now = Date.now();
    for (const f of readdirSync(STATE_DIR)) {
      const p = join(STATE_DIR, f);
      if (now - statSync(p).mtimeMs > STALE_MS) unlinkSync(p);
    }
  } catch {
    /* best effort */
  }
}

// ---------------------------------------------------------------- overrides

// Ordered: check the re-arm before the stand-down so "fm on" is never eaten by a
// looser pattern, and keep them anchored enough not to fire on prose.
const RE_ON = /\b(?:fm|frictionmax|friction-?maxx?ing)\s*[:=-]?\s*(?:on|back on|re-?arm)\b/i;
const RE_OFF = /\b(?:fm|frictionmax|friction-?maxx?ing)\s*[:=-]?\s*(?:off|down|stand ?down)\b/i;
const RE_ONE_TURN = /\bjust tell me\b/i;

// ---------------------------------------------------------------- payloads

function asset(name) {
  try {
    return readFileSync(join(HERE, name), 'utf8').trim();
  } catch {
    return '';
  }
}

const STOOD_DOWN =
  'friction-maxxing: STOOD DOWN for the rest of this session by explicit user override ' +
  '(`fm off`). Do not gate any decision. Do not mention the gate, do not ask whether they ' +
  'are sure, and do not offer a reduced version of it. Answer as if the skill did not exist. ' +
  'Re-arms only on `fm on`.';

const ONE_TURN =
  'friction-maxxing: one-turn bypass (`just tell me`). Answer this turn directly and completely, ' +
  'with no gate and no mention of it. The gate returns on the next turn.';

// Diagnostic trail, off unless FRICTIONMAX_DEBUG is set. Useful for confirming which
// events an agent actually delivers, since that varies by agent and by run mode.
function trace(line) {
  if (!process.env.FRICTIONMAX_DEBUG) return;
  try {
    mkdirSync(STATE_DIR, { recursive: true });
    appendFileSync(join(STATE_DIR, '_debug.log'), `${new Date().toISOString()} ${line}
`);
  } catch {
    /* diagnostics must never break a session either */
  }
}

function emit(eventName, text) {
  if (!text) return;
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: { hookEventName: eventName, additionalContext: text },
    })
  );
}

// ---------------------------------------------------------------- main

function main() {
  const raw = readStdin();
  let payload = {};
  try {
    payload = raw ? JSON.parse(raw) : {};
  } catch {
    payload = {};
  }

  const event = eventNameOf(payload);
  const sessionId = sessionIdOf(payload);
  trace(`event=${event || '(none)'} session=${sessionId} keys=${Object.keys(payload).join(',')}`);

  if (SESSION_START.has(event)) {
    sweepStale();
    // mandateSent stays false on purpose, so the first per-turn event re-sends the mandate.
    // The occasional duplicate costs ~350 tokens; a mandate that never lands costs the feature.
    saveState(sessionId, { armed: true, turn: 0, mandateSent: false });
    emit(event, asset('mandate.md'));
    return;
  }

  if (!PER_TURN.has(event)) return;

  const prompt = promptOf(payload);
  const state = loadState(sessionId);

  if (RE_ON.test(prompt)) {
    saveState(sessionId, { ...state, armed: true, turn: 0, mandateSent: true });
    emit(event, asset('mandate.md'));
    return;
  }

  if (RE_OFF.test(prompt)) {
    saveState(sessionId, { ...state, armed: false, turn: 0 });
    emit(event, STOOD_DOWN);
    return;
  }

  if (!state.armed) {
    // Re-assert the stand-down periodically: the mandate is still sitting in context and
    // will otherwise drift back into effect over a long session.
    const turn = (state.turn || 0) + 1;
    saveState(sessionId, { ...state, turn });
    if (turn % REARM_EVERY === 0) emit(event, STOOD_DOWN);
    return;
  }

  if (RE_ONE_TURN.test(prompt)) {
    emit(event, ONE_TURN);
    return;
  }

  const turn = (state.turn || 0) + 1;

  // First per-turn event of the session: this is the injection point we can actually rely on.
  if (!state.mandateSent) {
    saveState(sessionId, { ...state, turn, mandateSent: true });
    emit(event, asset('mandate.md'));
    return;
  }

  saveState(sessionId, { ...state, turn });
  if (turn % REARM_EVERY === 0) emit(event, asset('rearm.txt'));
}

try {
  main();
} catch {
  /* never break the session */
}
process.exit(0);
