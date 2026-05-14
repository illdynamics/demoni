import { describe, it, expect, beforeEach } from 'vitest';
import { filterStderrLine, _resetYoloCount } from '../src/stderr-filter.js';

describe('stderr-filter', () => {
  beforeEach(() => {
    _resetYoloCount();
  });

  describe('drops known warning lines', () => {
    it('drops true-color warning', () => {
      expect(filterStderrLine('Warning: True color (24-bit) support not detected. Using a terminal with true color enabled will result in a better visual experience.')).toBe('');
    });

    it('drops ripgrep fallback warning', () => {
      expect(filterStderrLine('Ripgrep is not available. Falling back to GrepTool.')).toBe('');
    });

    it('drops cleanup_ops startup phase warning', () => {
      expect(filterStderrLine("[STARTUP] Phase 'cleanup_ops' was started but never ended. Skipping metrics.")).toBe('');
    });

    it('drops cleanup_ops start mark warning', () => {
      expect(filterStderrLine("[STARTUP] Cannot measure phase 'cleanup_ops': start mark 'startup:cleanup_ops:start' not found (likely cleared by reset).")).toBe('');
    });
  });

  describe('YOLO deduplication', () => {
    it('allows first YOLO message', () => {
      const result = filterStderrLine('YOLO mode is enabled. All tool calls will be automatically approved.');
      expect(result).toContain('YOLO mode is enabled');
    });

    it('drops second YOLO message', () => {
      filterStderrLine('YOLO mode is enabled. All tool calls will be automatically approved.');
      const result = filterStderrLine('YOLO mode is enabled. All tool calls will be automatically approved.');
      expect(result).toBe('');
    });

    it('drops third YOLO message', () => {
      filterStderrLine('YOLO mode is enabled. All tool calls will be automatically approved.');
      filterStderrLine('YOLO mode is enabled. All tool calls will be automatically approved.');
      const result = filterStderrLine('YOLO mode is enabled. All tool calls will be automatically approved.');
      expect(result).toBe('');
    });
  });

  describe('no-input message replacement', () => {
    it('replaces gemini with demoni in no-input message', () => {
      const input = 'No input provided via stdin. Input can be provided by piping data into gemini or using the --prompt option.';
      const result = filterStderrLine(input);
      expect(result).toContain('demoni');
      expect(result).not.toContain('gemini');
    });
  });

  describe('passes through normal output', () => {
    it('passes through normal text', () => {
      expect(filterStderrLine('Hello world')).toBe('Hello world');
    });

    it('passes through error messages', () => {
      expect(filterStderrLine('Error: something went wrong')).toBe('Error: something went wrong');
    });

    it('passes through blank lines', () => {
      expect(filterStderrLine('   ')).toBe('   ');
    });
  });
});
