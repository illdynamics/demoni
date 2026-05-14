/**
 * Demoni stderr filter — suppresses known Gemini CLI startup warnings.
 *
 * The upstream Gemini CLI bundle emits several noisy startup messages that
 * we suppress: true-color warning, ripgrep fallback, cleanup_ops profiler
 * errors, duplicate YOLO messages, and stale "gemini" product name references.
 *
 * This filter is applied at the process boundary (child stderr → parent stderr)
 * so it never touches third-party code.
 *
 * ── Maintenance Policy ──────────────────────────────────────────
 * This is a PATCH-LAYER filter.  Upstream Gemini CLI may change
 * warning message formats between releases.  Maintainers must:
 *
 *   1. On each @google/gemini-cli upgrade, run the smoke test:
 *        DEEPSEEK_API_KEY=sk-test-key TERM=dumb CI=true \
 *          demoni -y 2>&1 | grep -i 'warning\|startup\|ripgrep'
 *
 *   2. If new warnings appear, add them as regexes in DROP_PATTERNS
 *      or exact strings in DROP_EXACT below.
 *
 *   3. Add corresponding tests in test/stderr-filter.test.ts.
 *
 *   4. If upstream merges a CLI flag/env var to suppress these
 *      messages natively, use that instead and deprecate the
 *      corresponding filter patterns.
 *
 *   This module is the ONLY place where upstream noise suppression
 *   should happen.  Do not spread such logic into cli.ts or other
 *   modules.
 * ─────────────────────────────────────────────────────────────────
 */

/** Set of exact-line-hash patterns to drop entirely. */
const DROP_EXACT: Set<string> = new Set([
  'Warning: True color (24-bit) support not detected. Using a terminal with true color enabled will result in a better visual experience.',
  'Ripgrep is not available. Falling back to GrepTool.',
  'Warning: True color (24-bit) support not detected.',
]);

/** Regex patterns to drop fully. */
const DROP_PATTERNS: RegExp[] = [
  /^Warning: True color \(24-bit\) support not detected/i,
  /^Warning: Basic terminal detected/i,
  /^Warning: 256.color support not detected/i,
  /^Ripgrep is not available\.\s*Falling back to GrepTool/i,
  /^\[STARTUP\] Phase '.*' was started but never ended\. Skipping metrics\.\s*$/,
  /^\[STARTUP\] Cannot measure phase '.*': start mark '.*' not found \(likely cleared by reset\)\.\s*$/,
];

/** Regex for "no input" message — replace with demoni-branded help. */
const NO_INPUT_PATTERN =
  /No input provided via stdin\. Input can be provided by piping data into gemini or using the --prompt option\./;

const NO_INPUT_REPLACEMENT =
  'No input provided. Use: demoni "your question here" or demoni --prompt "..." or pipe stdin.';

// ── YOLO deduplication tracker ─────────────────────────────────────

let yoloCount = 0;

// ── Export ──────────────────────────────────────────────────────────

/**
 * Filter a raw stderr line from the Gemini CLI child process.
 * Returns the line to write (or empty string to suppress).
 */
export function filterStderrLine(line: string): string {
  const trimmed = line.trim();
  if (!trimmed) return line; // preserve blank lines

  // 1. Exact-match drops
  if (DROP_EXACT.has(trimmed)) return '';

  // 2. Pattern-match drops
  for (const pat of DROP_PATTERNS) {
    if (pat.test(trimmed)) return '';
  }

  // 3. YOLO deduplication — allow only the first occurrence
  if (/yolo mode is enabled/i.test(trimmed)) {
    if (yoloCount > 0) return '';
    yoloCount += 1;
    return line;
  }

  // 4. "gemini" → "demoni" in no-input message
  if (NO_INPUT_PATTERN.test(trimmed)) {
    return line.replace(NO_INPUT_PATTERN, NO_INPUT_REPLACEMENT);
  }

  // 5. Pass through everything else
  return line;
}

/**
 * Reset YOLO counter (for testing).
 */
export function _resetYoloCount(): void {
  yoloCount = 0;
}
