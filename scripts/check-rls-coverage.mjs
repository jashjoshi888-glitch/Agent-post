/**
 * check-rls-coverage.mjs — static safety net (no database needed).
 *
 * Plain language: this script reads the database migration files and checks
 * that EVERY table holding user data has Row Level Security turned on.
 * It runs in seconds and can run in CI without any Supabase project.
 *
 * Run with:  npm run test:rls-coverage
 */
import { readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const migrationsDir = path.join(here, '..', 'supabase', 'migrations');

const files = readdirSync(migrationsDir)
  .filter((f) => f.endsWith('.sql'))
  .sort();

let allSql = '';
for (const f of files) {
  allSql += `\n-- file: ${f}\n` + readFileSync(path.join(migrationsDir, f), 'utf8');
}

// Strip SQL comments so commented-out code does not count.
const sqlWithoutComments = allSql.replace(/--[^\n]*/g, '');

// Find every "create table <schema>.<name>" (or "create table <name>").
const createRe = /create\s+table\s+(?:if\s+not\s+exists\s+)?(?:(\w+)\.)?(\w+)\s*\(/gi;
const tables = [];
let m;
while ((m = createRe.exec(sqlWithoutComments)) !== null) {
  const schema = m[1] ?? 'public';
  tables.push({ schema, name: m[2], full: `${schema}.${m[2]}` });
}

// Find every table with "enable row level security".
const rlsRe = /alter\s+table\s+(?:only\s+)?(?:(\w+)\.)?(\w+)\s+enable\s+row\s+level\s+security/gi;
const protectedTables = new Set();
while ((m = rlsRe.exec(sqlWithoutComments)) !== null) {
  const schema = m[1] ?? 'public';
  protectedTables.add(`${schema}.${m[2]}`);
}

let failed = 0;

console.log('RLS coverage check');
console.log('------------------');

if (tables.length === 0) {
  console.error('✗ No tables found in migrations — did the migration files change?');
  failed++;
}

for (const t of tables) {
  const ok = protectedTables.has(t.full);
  console.log(`${ok ? '✓' : '✗'} ${t.full} ${ok ? '— RLS enabled' : '— MISSING enable row level security!'}`);
  if (!ok) failed++;
}

// Every protected table should also have at least one policy.
const policyRe = /create\s+policy\s+"[^"]+"\s+on\s+(?:(\w+)\.)?(\w+)/gi;
const tablesWithPolicies = new Set();
while ((m = policyRe.exec(sqlWithoutComments)) !== null) {
  const schema = m[1] ?? 'public';
  tablesWithPolicies.add(`${schema}.${m[2]}`);
}
for (const t of tables) {
  if (!protectedTables.has(t.full)) continue;
  const ok = tablesWithPolicies.has(t.full);
  console.log(`${ok ? '✓' : '✗'} ${t.full} ${ok ? '— has policies' : '— has RLS but NO policies (everything would be blocked)!'}`);
  if (!ok) failed++;
}

console.log('------------------');
if (failed > 0) {
  console.error(`FAILED: ${failed} problem(s) found.`);
  process.exit(1);
}
console.log(`PASSED: ${tables.length} table(s) covered by Row Level Security.`);
