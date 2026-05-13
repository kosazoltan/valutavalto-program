#!/usr/bin/env node
/**
 * CI error digest collector.
 *
 * Mandatory goal: do not ask the operator to paste CI/Sourcery/Codex/Copilot
 * failures into chat. This script reads the available signals through gh and
 * local log files, then writes full failure blocks into .agent/ci/.
 */

import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { basename, join, resolve } from 'node:path';
import process from 'node:process';

const args = parseArgs(process.argv.slice(2));
const outputDir = resolve(process.cwd(), '.agent', 'ci');
mkdirSync(outputDir, { recursive: true });

const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
const outputPath = resolve(args.output ?? join(outputDir, `ci-error-digest-${timestamp}.md`));
const contextLines = Number.parseInt(args.context ?? '25', 10);
const maxBlocks = Number.parseInt(args.maxBlocks ?? '8', 10);
const maxLogChars = Number.parseInt(args.maxLogChars ?? '900000', 10);
const failOnFindings = Boolean(args.failOnFindings);
const reportOnly = Boolean(args.reportOnly);

const findings = [];
const sections = [];

section('CI Error Digest', [
  `Generated: ${new Date().toISOString()}`,
  `Working directory: ${process.cwd()}`,
  '',
  'Rule: collect complete failure blocks from CI, GitHub, Sourcery, Copilot, and Codex before fixing.',
]);

const ghStatus = run('gh', ['auth', 'status']);
if (!ghStatus.ok) {
  findings.push('gh auth status failed; GitHub/Sourcery/Copilot/Codex signals are not readable.');
  section('GitHub CLI', [
    'gh authentication is unavailable.',
    fence(redact(ghStatus.stderr || ghStatus.stdout || ghStatus.error || 'unknown gh auth failure')),
  ]);
} else {
  collectGitHubSignals();
}

collectLocalLogs();

section('Summary', findings.length === 0
  ? ['No blocking CI/review/local-log finding was detected by this collector.']
  : findings.map((finding) => `- ${finding}`));

writeFileSync(outputPath, sections.join('\n\n') + '\n', 'utf8');
console.log(`[ci-error-digest] wrote ${outputPath}`);
console.log(`[ci-error-digest] findings=${findings.length}`);

if (failOnFindings && !reportOnly && findings.length > 0) {
  process.exit(1);
}

function collectGitHubSignals() {
  const repoSlug = getRepoSlug();
  if (!repoSlug) {
    findings.push('GitHub repository slug could not be resolved.');
    section('GitHub Repository', ['gh repo view failed; run from a GitHub checkout with gh auth.']);
    return;
  }

  const prInfo = getPrInfo();
  section('GitHub Context', [
    `Repository: ${repoSlug}`,
    `PR: ${prInfo ? `#${prInfo.number} ${prInfo.title ?? ''}` : '(no current PR resolved)'}`,
    `Branch: ${runText('git', ['rev-parse', '--abbrev-ref', 'HEAD']) || '(unknown)'}`,
    `Head SHA: ${prInfo?.headRefOid ?? runText('git', ['rev-parse', 'HEAD']) ?? '(unknown)'}`,
    prInfo?.url ? `URL: ${prInfo.url}` : '',
  ].filter(Boolean));

  if (prInfo) {
    collectPrChecks(prInfo);
    collectReviewSignals(repoSlug, prInfo.number);
  }

  const headSha = prInfo?.headRefOid ?? runText('git', ['rev-parse', 'HEAD']);
  if (headSha) {
    collectCheckRuns(repoSlug, headSha);
    collectWorkflowRunLogs(repoSlug, headSha);
  }
}

function collectPrChecks(prInfo) {
  const checks = runJson('gh', [
    'pr',
    'checks',
    String(prInfo.number),
    '--json',
    'name,state,bucket,link,workflow,startedAt,completedAt',
  ]);

  if (!checks.ok) {
    section('PR Checks', ['Could not read `gh pr checks`.', fence(redact(checks.stderr || checks.error || ''))]);
    return;
  }

  const rows = Array.isArray(checks.data) ? checks.data : [];
  const rendered = rows.length === 0
    ? ['No PR checks were returned.']
    : rows.map((check) => {
      const bucket = check.bucket ?? check.state ?? 'unknown';
      if (['fail', 'cancel', 'timed_out'].includes(String(bucket).toLowerCase())) {
        findings.push(`PR check failed: ${check.name}`);
      }
      return `- [${bucket}] ${check.name}${check.workflow ? ` (${check.workflow})` : ''}${check.link ? ` - ${check.link}` : ''}`;
    });
  section('PR Checks', rendered);
}

function collectReviewSignals(repoSlug, prNumber) {
  const botPattern = /sourcery|codex|copilot/i;
  const reviews = runJson('gh', ['api', `/repos/${repoSlug}/pulls/${prNumber}/reviews?per_page=100`]);
  const comments = runJson('gh', ['api', `/repos/${repoSlug}/pulls/${prNumber}/comments?per_page=100`]);

  const lines = [];
  if (reviews.ok && Array.isArray(reviews.data)) {
    for (const review of reviews.data.filter((item) => botPattern.test(item.user?.login ?? ''))) {
      const body = redact(review.body ?? '').trim();
      lines.push(`## ${review.user.login} review: ${review.state}`);
      lines.push(`Submitted: ${review.submitted_at ?? '(unknown)'}`);
      lines.push(fence(trimBlock(body, 7000)));
      if (/CHANGES_REQUESTED/i.test(review.state ?? '') || hasBlockingText(body)) {
        findings.push(`${review.user.login} review has blocking signal.`);
      }
    }
  }

  if (comments.ok && Array.isArray(comments.data)) {
    for (const comment of comments.data.filter((item) => botPattern.test(item.user?.login ?? ''))) {
      const body = redact(comment.body ?? '').trim();
      lines.push(`## ${comment.user.login} inline: ${comment.path ?? '(unknown file)'}:${comment.line ?? comment.original_line ?? 0}`);
      lines.push(fence(trimBlock(body, 7000)));
      if (hasBlockingText(body)) {
        findings.push(`${comment.user.login} inline finding: ${comment.path ?? 'unknown file'}`);
      }
    }
  }

  section('Sourcery / Codex / Copilot Reviews', lines.length > 0 ? lines : ['No Sourcery, Codex, or Copilot review signal was returned.']);
}

function collectCheckRuns(repoSlug, headSha) {
  const runs = runJson('gh', ['api', `/repos/${repoSlug}/commits/${headSha}/check-runs?per_page=100`]);
  if (!runs.ok || !Array.isArray(runs.data?.check_runs)) {
    section('Check Run Annotations', ['Could not read check-runs for the current head SHA.']);
    return;
  }

  const lines = [];
  for (const runItem of runs.data.check_runs) {
    const conclusion = runItem.conclusion ?? runItem.status ?? 'unknown';
    const annotationCount = runItem.output?.annotations_count ?? 0;
    if (['failure', 'timed_out', 'cancelled', 'action_required'].includes(String(conclusion))) {
      findings.push(`Check run failed: ${runItem.name}`);
      lines.push(`## [${conclusion}] ${runItem.name} (${runItem.app?.name ?? 'unknown app'})`);
      if (runItem.details_url) lines.push(runItem.details_url);
    }

    if (annotationCount > 0) {
      const annotations = runJson('gh', ['api', `/repos/${repoSlug}/check-runs/${runItem.id}/annotations?per_page=100`]);
      if (annotations.ok && Array.isArray(annotations.data)) {
        lines.push(`## Annotations: ${runItem.name}`);
        for (const annotation of annotations.data.slice(0, 30)) {
          const message = [
            `${annotation.annotation_level ?? 'annotation'} ${annotation.path ?? ''}:${annotation.start_line ?? 0}`,
            annotation.title ?? '',
            annotation.message ?? '',
            annotation.raw_details ?? '',
          ].filter(Boolean).join('\n');
          lines.push(fence(trimBlock(redact(message), 4000)));
          if (/failure|error/i.test(annotation.annotation_level ?? '')) {
            findings.push(`Check annotation: ${runItem.name} ${annotation.path ?? ''}:${annotation.start_line ?? 0}`);
          }
        }
      }
    }
  }

  section('Check Run Annotations', lines.length > 0 ? lines : ['No failed check-runs or annotations were returned.']);
}

function collectWorkflowRunLogs(repoSlug, headSha) {
  const runs = runJson('gh', ['api', `/repos/${repoSlug}/actions/runs?head_sha=${headSha}&per_page=20`]);
  if (!runs.ok || !Array.isArray(runs.data?.workflow_runs)) {
    section('GitHub Actions Failed Logs', ['Could not read workflow runs for the current head SHA.']);
    return;
  }

  const failedRuns = runs.data.workflow_runs.filter((item) =>
    ['failure', 'timed_out', 'cancelled', 'startup_failure', 'action_required'].includes(String(item.conclusion)));

  if (failedRuns.length === 0) {
    section('GitHub Actions Failed Logs', ['No failed GitHub Actions workflow run was found for the current head SHA.']);
    return;
  }

  const lines = [];
  for (const workflowRun of failedRuns.slice(0, 8)) {
    findings.push(`GitHub Actions workflow failed: ${workflowRun.name} #${workflowRun.run_number}`);
    lines.push(`## ${workflowRun.name} #${workflowRun.run_number}`);
    lines.push(`Conclusion: ${workflowRun.conclusion}`);
    lines.push(`URL: ${workflowRun.html_url}`);

    const log = run('gh', ['run', 'view', String(workflowRun.id), '--log-failed'], { maxBuffer: maxLogChars + 200000 });
    const fallbackLog = log.ok && log.stdout.trim()
      ? log
      : run('gh', ['run', 'view', String(workflowRun.id), '--log'], { maxBuffer: maxLogChars + 200000 });
    const raw = redact((fallbackLog.stdout || fallbackLog.stderr || '').slice(-maxLogChars));
    const rawPath = join(outputDir, `raw-run-${workflowRun.id}.log`);
    writeFileSync(rawPath, raw, 'utf8');
    lines.push(`Raw log: ${rawPath}`);
    lines.push(...renderBlocks(raw, `run ${workflowRun.id}`));
  }

  section('GitHub Actions Failed Logs', lines);
}

function collectLocalLogs() {
  const defaultDirs = ['/tmp/logs', '/tmp'];
  const configuredDirs = (process.env.CI_DIGEST_LOCAL_LOG_DIRS ?? '')
    .split(';')
    .map((item) => item.trim())
    .filter(Boolean);
  const dirs = [...configuredDirs, ...defaultDirs];
  const files = [];

  for (const dir of dirs) {
    if (!existsSync(dir)) continue;
    for (const file of safeReadDir(dir)) {
      const full = join(dir, file);
      if (!/\.log$/i.test(file)) continue;
      try {
        const stat = statSync(full);
        if (stat.isFile()) files.push({ full, mtimeMs: stat.mtimeMs, size: stat.size });
      } catch {
        // ignored
      }
    }
  }

  const lines = [];
  for (const file of files.sort((a, b) => b.mtimeMs - a.mtimeMs).slice(0, 20)) {
    const content = redact(readFileSync(file.full, 'utf8').slice(-maxLogChars));
    const blocks = renderBlocks(content, basename(file.full));
    if (blocks.length > 0) {
      findings.push(`Local log has error block: ${file.full}`);
      lines.push(`## ${file.full}`);
      lines.push(`Size: ${file.size} bytes`);
      lines.push(...blocks);
    }
  }

  section('Codex / Local Logs', lines.length > 0 ? lines : ['No local error blocks were found in /tmp/logs or /tmp.']);
}

function renderBlocks(text, label) {
  const lines = text.split(/\r?\n/);
  const hits = [];
  const pattern = /(::error|error|failed|failure|exception|caused by|npm err|build failure|compilation failure|assertionerror|typeerror|referenceerror|process completed with exit code|tests run:.*failures|failures?: [1-9]|fatal)/i;

  for (let i = 0; i < lines.length; i += 1) {
    if (pattern.test(lines[i])) {
      hits.push(i);
    }
  }

  if (hits.length === 0) return [];

  const ranges = [];
  for (const hit of hits) {
    const start = Math.max(0, hit - contextLines);
    const end = Math.min(lines.length - 1, hit + contextLines);
    const last = ranges.at(-1);
    if (last && start <= last.end + 5) {
      last.end = Math.max(last.end, end);
    } else {
      ranges.push({ start, end });
    }
  }

  return ranges.slice(0, maxBlocks).flatMap((range, index) => {
    const block = lines
      .slice(range.start, range.end + 1)
      .join('\n');
    return [
      `### ${label} block ${index + 1} (${range.start + 1}-${range.end + 1})`,
      fence(trimBlock(block, 14000)),
    ];
  });
}

function getRepoSlug() {
  const value = runText('gh', ['repo', 'view', '--json', 'nameWithOwner', '--jq', '.nameWithOwner']);
  return value?.trim() || null;
}

function getPrInfo() {
  const prArg = args.pr ?? args.PR;
  const command = prArg
    ? ['pr', 'view', String(prArg), '--json', 'number,title,headRefOid,headRefName,baseRefName,url,state,reviewDecision,mergeStateStatus']
    : ['pr', 'view', '--json', 'number,title,headRefOid,headRefName,baseRefName,url,state,reviewDecision,mergeStateStatus'];
  const result = runJson('gh', command);
  return result.ok ? result.data : null;
}

function hasBlockingText(text) {
  return /(changes requested|p0|p1|bug[_ -]?risk|security|must fix|blocking|error|failure|failed)/i.test(text ?? '');
}

function trimBlock(text, maxChars) {
  if (!text || text.length <= maxChars) return text || '';
  return `${text.slice(0, Math.floor(maxChars / 2))}\n\n[... trimmed by ci-error-digest ...]\n\n${text.slice(-Math.floor(maxChars / 2))}`;
}

function redact(text) {
  return String(text ?? '')
    .replace(/(authorization\s*:\s*bearer\s+)[^\s"']+/gi, '$1[REDACTED]')
    .replace(/(token|secret|password|passwd|jwt|api[_-]?key|client[_-]?secret|private[_-]?key)(\s*[:=]\s*)[^\s"']+/gi, '$1$2[REDACTED]')
    .replace(/\bghp_[A-Za-z0-9_]{20,}\b/g, '[REDACTED_GITHUB_TOKEN]')
    .replace(/\bgithub_pat_[A-Za-z0-9_]{20,}\b/g, '[REDACTED_GITHUB_TOKEN]')
    .replace(/\bya29\.[A-Za-z0-9._-]{20,}\b/g, '[REDACTED_GOOGLE_TOKEN]');
}

function section(title, lines) {
  sections.push(`## ${title}\n\n${lines.filter((line) => line !== undefined && line !== null).join('\n')}`);
}

function fence(text) {
  return `\`\`\`text\n${text ?? ''}\n\`\`\``;
}

function runJson(command, commandArgs) {
  const result = run(command, commandArgs);
  if (!result.ok) return result;
  try {
    return { ok: true, data: JSON.parse(result.stdout || 'null') };
  } catch (error) {
    return { ok: false, stdout: result.stdout, stderr: result.stderr, error: error.message };
  }
}

function runText(command, commandArgs) {
  const result = run(command, commandArgs);
  return result.ok ? result.stdout.trim() : null;
}

function run(command, commandArgs, options = {}) {
  try {
    const stdout = execFileSync(command, commandArgs, {
      cwd: process.cwd(),
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
      maxBuffer: options.maxBuffer ?? 20 * 1024 * 1024,
    });
    return { ok: true, stdout, stderr: '' };
  } catch (error) {
    return {
      ok: false,
      stdout: error.stdout?.toString?.() ?? '',
      stderr: error.stderr?.toString?.() ?? '',
      error: error.message,
      code: error.status,
    };
  }
}

function safeReadDir(dir) {
  try {
    return readdirSync(dir);
  } catch {
    return [];
  }
}

function parseArgs(argv) {
  const parsed = {};
  for (let i = 0; i < argv.length; i += 1) {
    const item = argv[i];
    if (!item.startsWith('--')) continue;
    const key = item.slice(2).replace(/-([a-z])/g, (_, char) => char.toUpperCase());
    const next = argv[i + 1];
    if (!next || next.startsWith('--')) {
      parsed[key] = true;
    } else {
      parsed[key] = next;
      i += 1;
    }
  }
  return parsed;
}
