#!/usr/bin/env node
// visual-tests.mjs — Playwright visual validation for interactive-docs sites
// Usage: node visual-tests.mjs <base-url> [screenshots-dir]
// Output: JSON results to stdout
// Exit: 0 if all pass, 1 if any issues found
//
// IMPORTANT: This file is copied into the docs project directory before execution
// so that ESM module resolution finds the locally-installed playwright package.

import { chromium } from 'playwright';
import { mkdirSync, existsSync } from 'fs';
import { join } from 'path';

const BASE_URL = process.argv[2] || 'http://localhost:5173';
const SCREENSHOTS_DIR = process.argv[3] || '/tmp/docs-screenshots';

const VIEWS = [
  { route: '/',              name: 'System Overview',    renderer: 'reactflow' },
  { route: '/components',    name: 'Component Graph',    renderer: 'reactflow' },
  { route: '/data-flow',     name: 'Data Flow',          renderer: 'reactflow' },
  { route: '/sequences',     name: 'Sequence Diagrams',  renderer: 'mermaid' },
  { route: '/erd',           name: 'ERD',                renderer: 'mermaid' },
  { route: '/state-machines',name: 'State Machines',     renderer: 'mermaid' },
  { route: '/api',           name: 'API Contracts',      renderer: 'custom' },
  { route: '/dependencies',  name: 'Dependency Graph',   renderer: 'reactflow' },
  { route: '/tech-stack',    name: 'Tech Stack',         renderer: 'custom' },
  { route: '/adrs',          name: 'ADRs',               renderer: 'custom' },
];

// Wait for the view-specific content to render (fixes identical-screenshot issue)
async function waitForViewContent(page, view) {
  try {
    if (view.renderer === 'reactflow') {
      await page.waitForSelector('.react-flow, .react-flow__renderer, [class*="reactflow"]', { timeout: 10000 });
    } else if (view.renderer === 'mermaid') {
      await page.waitForSelector('svg', { timeout: 10000 });
    } else {
      await page.waitForSelector('main h1, main h2, main [class*="card"], main table, main [class*="Card"]', { timeout: 10000 });
    }
  } catch {
    // Timeout — will be caught by content checks below
  }
}

async function validateView(page, view, screenshotsDir) {
  const result = { route: view.route, name: view.name, status: 'pass', issues: [], screenshot: null };

  try {
    const response = await page.goto(`${BASE_URL}${view.route}`, { waitUntil: 'networkidle', timeout: 15000 });

    if (!response || response.status() >= 400) {
      result.issues.push(`HTTP ${response?.status() || 'no response'} on ${view.route}`);
      result.status = 'fail';
      return result;
    }

    // Wait for view-specific content to render
    await waitForViewContent(page, view);

    // Check: Mermaid rendering errors
    if (view.renderer === 'mermaid') {
      const mermaidErrors = await page.locator('.mermaid-error, [id*="mermaid"] .error').count();
      if (mermaidErrors > 0) {
        result.issues.push(`Mermaid rendering error found (${mermaidErrors} instance(s))`);
      }
      const anySvgs = await page.locator('svg').count();
      if (anySvgs === 0) {
        result.issues.push('No Mermaid diagrams rendered — expected at least one SVG');
      }
    }

    // Check: React Flow canvas present
    if (view.renderer === 'reactflow') {
      const rfCanvas = await page.locator('.react-flow, .react-flow__renderer, [class*="reactflow"]').count();
      if (rfCanvas === 0) {
        result.issues.push('React Flow canvas not found — expected interactive graph');
      }
    }

    // Check: view has meaningful content
    const textContent = await page.evaluate(() => {
      const el = document.querySelector('main') || document.querySelector('[role="main"]') || document.body;
      return el.innerText.trim();
    });
    if (textContent.length < 20) {
      result.issues.push(`View appears empty — only ${textContent.length} chars of content`);
    }

    // Check: sidebar navigation (wait for hydration instead of static timeout)
    try {
      await page.waitForFunction(
        () => document.querySelectorAll('nav a, aside a, [class*="sidebar"] a, [class*="Sidebar"] a').length >= 5,
        { timeout: 10000 }
      );
    } catch {
      const count = await page.locator('nav a, aside a, [class*="sidebar"] a, [class*="Sidebar"] a').count();
      result.issues.push(`Sidebar navigation incomplete — found ${count} links, expected ~10`);
    }

    // Take screenshot after content is rendered
    const screenshotName = view.route === '/' ? 'overview' : view.route.replace(/^\//, '');
    const screenshotPath = join(screenshotsDir, `${screenshotName}.png`);
    await page.screenshot({ path: screenshotPath, fullPage: false });
    result.screenshot = screenshotPath;

    if (result.issues.length > 0) result.status = 'issues';
  } catch (err) {
    result.issues.push(`Navigation failed: ${err.message}`);
    result.status = 'fail';
  }

  return result;
}

async function run() {
  if (!existsSync(SCREENSHOTS_DIR)) mkdirSync(SCREENSHOTS_DIR, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await context.newPage();

  const jsErrors = [];
  page.on('pageerror', (err) => jsErrors.push(err.message));

  const results = { passed: true, jsErrors: [], views: [] };

  for (const view of VIEWS) {
    const viewResult = await validateView(page, view, SCREENSHOTS_DIR);
    results.views.push(viewResult);
    if (viewResult.status !== 'pass') results.passed = false;
  }

  if (jsErrors.length > 0) {
    results.jsErrors = jsErrors;
    results.passed = false;
  }

  await browser.close();
  console.log(JSON.stringify(results, null, 2));
  process.exit(results.passed ? 0 : 1);
}

run().catch((err) => {
  console.error(JSON.stringify({ passed: false, error: err.message, views: [] }));
  process.exit(1);
});
