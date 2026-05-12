/**
 * Docker Smoke Test
 *
 * Builds the Docker image and verifies demoni works inside the container.
 * Skipped if docker is not available or image can't be built.
 */
import { describe, it, expect, beforeAll } from 'vitest';
import { execSync, spawnSync } from 'node:child_process';

const IMAGE = 'demoni:test';

function dockerAvailable(): boolean {
  try {
    execSync('docker info', { stdio: 'ignore', timeout: 5000 });
    return true;
  } catch {
    return false;
  }
}

function buildImage(): void {
  execSync(`docker build -t ${IMAGE} .`, {
    cwd: process.cwd(),
    stdio: 'pipe',
    timeout: 120_000,
  });
}

function runInContainer(args: string[], env: Record<string, string> = {}): { stdout: string; stderr: string; exitCode: number } {
  const envArgs: string[] = [];
  for (const [k, v] of Object.entries(env)) {
    envArgs.push('-e', `${k}=${v}`);
  }
  const result = spawnSync(
    'docker',
    ['run', '--rm', ...envArgs, IMAGE, ...args],
    { encoding: 'utf-8', timeout: 60_000, maxBuffer: 10_000_000 },
  );
  return {
    stdout: result.stdout || '',
    stderr: result.stderr || '',
    exitCode: result.status ?? -1,
  };
}

// Only run if Docker is available
const RUN_TESTS = dockerAvailable();

describe.runIf(RUN_TESTS)('Docker Smoke Test', () => {
  beforeAll(() => {
    buildImage();
  }, 180_000);

  it('demoni --help works inside container', () => {
    const result = runInContainer(['demoni', '--help']);
    expect(result.stdout).toContain('Demoni');
    expect(result.stdout).toContain('v4-flash');
    expect(result.exitCode).toBe(0);
  });

  it('demoni --version works inside container', () => {
    const result = runInContainer(['demoni', '--version']);
    expect(result.stdout).toContain('demoni v');
    expect(result.exitCode).toBe(0);
  });

  it('demoni with DEEPSEEK_API_KEY exits cleanly (no Google auth attempt)', () => {
    const result = runInContainer(
      ['demoni', '--version'],
      { DEEPSEEK_API_KEY: 'sk-test-key' },
    );
    expect(result.exitCode).toBe(0);
    expect(result.stderr).not.toContain('Google');
    expect(result.stderr).not.toContain('OAuth');
  });

  it('gemini CLI is available inside container', () => {
    const result = runInContainer(['gemini', '--version']);
    expect(result.exitCode).toBe(0);
  });

  it('bridge scripts are present', () => {
    const result = runInContainer(['ls', '/opt/demoni/bridge/dist/server.js']);
    expect(result.exitCode).toBe(0);
  });

  it('model catalog is present', () => {
    const result = runInContainer(['cat', '/opt/demoni/config/model-catalog.json']);
    expect(result.stdout).toContain('v4-flash');
    expect(result.stdout).toContain('v4-pro');
    expect(result.exitCode).toBe(0);
  });
});
