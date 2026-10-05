/**
 * rls-verify.mjs — live two-account security check against a real Supabase
 * project (dev or production).
 *
 * Plain language:
 *   This script signs up two throwaway agents (A and B), then tries every
 *   cross-account attack the app must withstand: B reading A's data, B
 *   editing A's data, B touching A's uploaded files, and users tampering
 *   with their own subscription plan. It prints a PASS/FAIL list and always
 *   deletes the throwaway accounts at the end.
 *
 *   It is the "verified by tests" checkbox in the Phase 1 acceptance
 *   criteria — run it once against your dev Supabase project and save the
 *   output.
 *
 * Needs three environment variables (never commit these values):
 *   SUPABASE_URL               e.g. https://xxxx.supabase.co
 *   SUPABASE_ANON_KEY          "anon" / public key (safe in the app)
 *   SUPABASE_SERVICE_ROLE_KEY  secret "service_role" key (server only!)
 *
 * Run with:
 *   npm run test:rls-live
 */
import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const anonKey = process.env.SUPABASE_ANON_KEY;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !anonKey || !serviceKey) {
  console.error(
    'Missing environment variables.\n' +
      'Set SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY\n' +
      '(see supabase/.env.example).'
  );
  process.exit(1);
}

// The "server" client (can do anything) — used to create/delete test users.
const server = createClient(url, serviceKey, { auth: { persistSession: false } });

let passed = 0;
let failed = 0;
function check(name, ok, detail = '') {
  if (ok) {
    passed++;
    console.log(`✓ ${name}`);
  } else {
    failed++;
    console.error(`✗ ${name}${detail ? ` — ${detail}` : ''}`);
  }
}

const stamp = Date.now();
const password = `Rls-Verify-${stamp}!`;
const aEmail = `rls-a-${stamp}@example.com`;
const bEmail = `rls-b-${stamp}@example.com`;

let userA = null;
let userB = null;

// 1x1 transparent PNG, for the file-upload tests.
const tinyPng = Uint8Array.from(
  Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    'base64'
  )
);

try {
  // -------------------------------------------------------------------------
  // Create two throwaway accounts.
  // -------------------------------------------------------------------------
  console.log('Creating two throwaway test accounts...');
  const { data: aData, error: aErr } = await server.auth.admin.createUser({
    email: aEmail,
    password,
    email_confirm: true,
  });
  const { data: bData, error: bErr } = await server.auth.admin.createUser({
    email: bEmail,
    password,
    email_confirm: true,
  });
  if (aErr || bErr) throw new Error(`could not create test users: ${aErr?.message ?? bErr?.message}`);
  userA = aData.user;
  userB = bData.user;
  console.log(`  A = ${aEmail}\n  B = ${bEmail}`);

  // -------------------------------------------------------------------------
  // Automatic free plan at sign-up.
  // -------------------------------------------------------------------------
  const { data: entA } = await server
    .from('entitlements')
    .select('plan, source')
    .eq('user_id', userA.id)
    .single();
  check('new user A automatically got a free entitlement', entA?.plan === 'free' && entA?.source === 'signup');

  // -------------------------------------------------------------------------
  // Sign in as A and as B (two separate app sessions).
  // -------------------------------------------------------------------------
  const clientA = createClient(url, anonKey, { auth: { persistSession: false } });
  const clientB = createClient(url, anonKey, { auth: { persistSession: false } });

  const { error: signInAErr } = await clientA.auth.signInWithPassword({ email: aEmail, password });
  const { error: signInBErr } = await clientB.auth.signInWithPassword({ email: bEmail, password });
  check('both test accounts can sign in', !signInAErr && !signInBErr, signInAErr?.message ?? signInBErr?.message);

  // -------------------------------------------------------------------------
  // A manages their own data (this must work).
  // -------------------------------------------------------------------------
  const { error: updOwnErr } = await clientA
    .from('profiles')
    .update({ agency_name: 'A Insurance Co', onboarding_completed: true })
    .eq('id', userA.id)
    .select();
  check('A can edit their own profile', !updOwnErr);

  const { data: ownProfile } = await clientA.from('profiles').select('*').eq('id', userA.id).single();
  check('A can read their own profile', ownProfile?.agency_name === 'A Insurance Co');

  // -------------------------------------------------------------------------
  // B attacks A (all of these must fail).
  // -------------------------------------------------------------------------
  const { data: bSeesA } = await clientB.from('profiles').select('*').eq('id', userA.id);
  check("B cannot read A's profile", Array.isArray(bSeesA) && bSeesA.length === 0);

  const { data: bUpdA, error: bUpdErr } = await clientB
    .from('profiles')
    .update({ agency_name: 'HACKED' })
    .eq('id', userA.id)
    .select();
  check("B cannot modify A's profile", !bUpdErr && Array.isArray(bUpdA) && bUpdA.length === 0);

  const { data: bSeesBrand } = await clientB.from('brand_kits').select('*').eq('user_id', userA.id);
  check("B cannot read A's brand kit", Array.isArray(bSeesBrand) && bSeesBrand.length === 0);

  const { error: bEntErr } = await clientB
    .from('entitlements')
    .insert({ user_id: userA.id, plan: 'pro' });
  check('B cannot create entitlements for A', !!bEntErr);

  const { error: bLegalErr } = await clientB
    .from('legal_acceptances')
    .insert({ user_id: userA.id, document_type: 'terms', document_version: 'v1' });
  check('B cannot record legal acceptances for A', !!bLegalErr);

  // -------------------------------------------------------------------------
  // Plans are server-managed: nobody can upgrade themselves.
  // -------------------------------------------------------------------------
  const { error: selfPlanErr } = await clientA.from('entitlements').update({ plan: 'pro' }).eq('user_id', userA.id);
  const { data: planAfter } = await server.from('entitlements').select('plan').eq('user_id', userA.id).single();
  check("A cannot upgrade their own plan", !!selfPlanErr && planAfter?.plan === 'free');

  // -------------------------------------------------------------------------
  // Uploaded files follow the same rules.
  // -------------------------------------------------------------------------
  const aFilePath = `${userA.id}/verify-${stamp}.png`;
  const bEvilPath = `${userA.id}/evil-${stamp}.png`;
  const bOwnPath = `${userB.id}/verify-${stamp}.png`;

  const { error: upAErr } = await clientA.storage.from('avatars').upload(aFilePath, tinyPng, {
    contentType: 'image/png',
  });
  check('A can upload a photo to their own folder', !upAErr, upAErr?.message);

  const { data: downA, error: downAErr } = await clientB.storage.from('avatars').download(aFilePath);
  check("B cannot download A's photo", !!downAErr && !downA);

  const { error: upEvilErr } = await clientB.storage.from('avatars').upload(bEvilPath, tinyPng, {
    contentType: 'image/png',
  });
  check('B cannot upload a file into A\'s folder', !!upEvilErr);

  const { data: delA, error: delAErr } = await clientB.storage.from('avatars').remove([aFilePath]);
  const { error: stillThereErr, data: stillThere } = await clientA.storage.from('avatars').download(aFilePath);
  check("B cannot delete A's photo", (!!delAErr || (Array.isArray(delA) && delA.length === 0)) && !stillThereErr && !!stillThere);

  const { error: upBErr } = await clientB.storage.from('avatars').upload(bOwnPath, tinyPng, {
    contentType: 'image/png',
  });
  check('B can upload a photo to their own folder', !upBErr, upBErr?.message);
} finally {
  // -------------------------------------------------------------------------
  // Clean up the throwaway accounts (and their rows/files with them).
  // -------------------------------------------------------------------------
  console.log('Cleaning up throwaway accounts...');
  for (const u of [userA, userB]) {
    if (u) {
      await server.auth.admin.deleteUser(u.id);
    }
  }
}

console.log('----------------------------------------');
console.log(`PASSED: ${passed}   FAILED: ${failed}`);
if (failed > 0) {
  console.error('Security verification FAILED — do not ship.');
  process.exit(1);
}
console.log('Live security verification passed.');
