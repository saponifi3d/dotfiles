/**
 * vim-editor.ts — modal (vim-like) editing for the Pi prompt editor.
 *
 * Extends the official example at
 *   packages/coding-agent/examples/extensions/modal-editor.ts
 * which ships h/j/k/l/0/$/x/i/a. This adds word motions, operators (d/c),
 * counts, line-wise commands, and open-line.
 *
 * Install:
 *   cp vim-editor.ts ~/.pi/agent/extensions/vim-editor.ts
 *   # then in pi:  /reload
 *
 * Modes:
 *   Insert (default) — everything types through normally.
 *   Normal           — Escape from insert. Escape again aborts the agent run.
 *
 * Normal mode:
 *   motions    h j k l w e b 0 ^ $        (accept counts, e.g. 3w)
 *   insert     i a I A o O
 *   edits      x X s S D C p
 *   operators  dw db dd d$ d0 dh dl  /  cw cb cc c$ c0
 *
 * HOW THIS WORKS (and its limits): Pi's editor has no vim engine. This
 * translates normal-mode keys into the terminal control sequences that Pi's
 * default readline-style keybindings already understand. So it is a faithful
 * *feel*, not a faithful vim: there is no undo tree, no registers, no text
 * objects (ciw, di"), no visual mode, and no marks. `p` pastes Pi's kill-ring
 * (ctrl+y), not a vim register.
 *
 * IMPORTANT: j/k at the first/last line browse prompt history — that is Pi's
 * built-in cursorUp/cursorDown behavior, not a bug here. Counts are capped so
 * a stray `999j` cannot stampede through your history.
 *
 * If you rebind tui.editor.* keys in keybindings.json away from the defaults
 * listed beside each sequence below, update K to match.
 */

import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

/** Control sequences matching Pi's DEFAULT tui.editor.* / tui.input.* bindings. */
const K = {
	left: "\x1b[D", // cursorLeft
	right: "\x1b[C", // cursorRight
	up: "\x1b[A", // cursorUp
	down: "\x1b[B", // cursorDown
	lineStart: "\x01", // ctrl+a  cursorLineStart
	lineEnd: "\x05", // ctrl+e  cursorLineEnd
	wordLeft: "\x1bb", // alt+b   cursorWordLeft
	wordRight: "\x1bf", // alt+f   cursorWordRight
	backspace: "\x7f", // deleteCharBackward
	delForward: "\x1b[3~", // deleteCharForward
	delWordBack: "\x17", // ctrl+w  deleteWordBackward
	delWordForward: "\x1bd", // alt+d   deleteWordForward
	delToLineStart: "\x15", // ctrl+u  deleteToLineStart
	delToLineEnd: "\x0b", // ctrl+k  deleteToLineEnd
	yank: "\x19", // ctrl+y  yank
	newLine: "\x0a", // ctrl+j  input.newLine
} as const;

const MAX_COUNT = 100;

type Mode = "normal" | "insert";
type Operator = "d" | "c";

class VimEditor extends CustomEditor {
	private mode: Mode = "insert";
	private count = "";
	private operator: Operator | null = null;

	// --- input routing ----------------------------------------------------

	handleInput(data: string): void {
		if (matchesKey(data, "escape")) {
			if (this.mode === "insert") {
				this.mode = "normal";
				this.clearPending();
			} else if (this.operator !== null || this.count !== "") {
				this.clearPending(); // cancel half-typed command, stay in normal
			} else {
				super.handleInput(data); // abort agent run
			}
			return;
		}

		if (this.mode === "insert") {
			super.handleInput(data);
			return;
		}

		this.handleNormal(data);
	}

	private handleNormal(data: string): void {
		// Accumulate count prefix. Bare "0" is the line-start motion.
		if (/^[1-9]$/.test(data) || (data === "0" && this.count !== "")) {
			this.count += data;
			return;
		}

		const n = Math.min(Math.max(parseInt(this.count || "1", 10) || 1, 1), MAX_COUNT);
		const op = this.operator;
		this.clearPending();

		if (op !== null) {
			this.applyOperator(op, data, n);
			return;
		}

		switch (data) {
			// motions
			case "h": return this.repeat(K.left, n);
			case "l": return this.repeat(K.right, n);
			case "j": return this.repeat(K.down, n);
			case "k": return this.repeat(K.up, n);
			case "w":
			case "e": return this.repeat(K.wordRight, n);
			case "b": return this.repeat(K.wordLeft, n);
			case "0":
			case "^": return this.send(K.lineStart);
			case "$": return this.send(K.lineEnd);

			// enter insert mode
			case "i": this.mode = "insert"; return;
			case "a": this.send(K.right); this.mode = "insert"; return;
			case "I": this.send(K.lineStart); this.mode = "insert"; return;
			case "A": this.send(K.lineEnd); this.mode = "insert"; return;
			case "o":
				this.send(K.lineEnd);
				this.send(K.newLine);
				this.mode = "insert";
				return;
			case "O":
				this.send(K.lineStart);
				this.send(K.newLine);
				this.send(K.up);
				this.mode = "insert";
				return;

			// single-key edits
			case "x": return this.repeat(K.delForward, n);
			case "X": return this.repeat(K.backspace, n);
			case "s": this.send(K.delForward); this.mode = "insert"; return;
			case "D": return this.send(K.delToLineEnd);
			case "C": this.send(K.delToLineEnd); this.mode = "insert"; return;
			case "S":
				this.send(K.lineStart);
				this.send(K.delToLineEnd);
				this.mode = "insert";
				return;
			case "p": return this.send(K.yank);

			// pending operators
			case "d": this.operator = "d"; return;
			case "c": this.operator = "c"; return;
		}

		// Swallow unmapped printable keys so they don't leak into the buffer.
		// Pass control sequences (ctrl+c, enter, tab, ...) through to Pi.
		if (data.length === 1 && data.charCodeAt(0) >= 32) return;
		super.handleInput(data);
	}

	private applyOperator(op: Operator, motion: string, n: number): void {
		// dd / cc — line-wise
		if (motion === op) {
			this.send(K.lineStart);
			this.send(K.delToLineEnd);
			if (op === "c") this.mode = "insert";
			return;
		}

		switch (motion) {
			case "w":
			case "e": this.repeat(K.delWordForward, n); break;
			case "b": this.repeat(K.delWordBack, n); break;
			case "$": this.send(K.delToLineEnd); break;
			case "0":
			case "^": this.send(K.delToLineStart); break;
			case "h": this.repeat(K.backspace, n); break;
			case "l": this.repeat(K.delForward, n); break;
			default: return; // unsupported motion — abort, change nothing
		}

		if (op === "c") this.mode = "insert";
	}

	// --- helpers ----------------------------------------------------------

	private send(seq: string): void {
		super.handleInput(seq);
	}

	private repeat(seq: string, times: number): void {
		for (let i = 0; i < times; i++) super.handleInput(seq);
	}

	private clearPending(): void {
		this.count = "";
		this.operator = null;
	}

	// --- rendering --------------------------------------------------------

	render(width: number): string[] {
		const lines = super.render(width);
		if (lines.length === 0) return lines;

		const pending = `${this.count}${this.operator ?? ""}`;
		const label =
			this.mode === "normal"
				? pending
					? ` NORMAL ${pending} `
					: " NORMAL "
				: " INSERT ";

		const last = lines.length - 1;
		if (visibleWidth(lines[last]!) >= label.length) {
			lines[last] = truncateToWidth(lines[last]!, width - label.length, "") + label;
		}
		return lines;
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return; // editor components are TUI-only
		ctx.ui.setEditorComponent((tui, theme, kb) => new VimEditor(tui, theme, kb));
	});
}
