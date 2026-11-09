'use strict';
// #345 read-only Production signed-JWT release gate. No Auth user creation,
// business writes, uploads, role impersonation, or downloaded file contents.
// Credentials and JWTs remain in memory; output contains only PASS/BLOCKED.
const { stdin, stdout, stderr } = require('node:process');
const readline = require('node:readline/promises');
const host = 'rkhmfbxlduuovlbsxhgy.supabase.co';
const base = 'https://' + host;
const bucket = 'driver-documents';
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
let passCount = 0;
function pass(ok, label) {
  if (!ok) throw Error('FAIL ' + label);
  passCount++;
  stdout.write('PASS  ' + label + '\n');
}
function publicKey() {
  const k = (process.env.HORUS_PROD_PUBLISHABLE_KEY || '').trim();
  if (k.startsWith('sb_publishable_')) return k;
  const parts = k.split('.');
  if (parts.length !== 3) throw Error('A publishable or legacy anon key is required.');
  let payload;
  try { payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString()); }
  catch (_) { throw Error('Invalid anon key.'); }
  if (payload.role !== 'anon') throw Error('Refusing service_role or privileged API key.');
  return k;
}
function isAllowed(method, path) {
  const get = ['/auth/v1/user','/rest/v1/company_users','/rest/v1/routes',
    '/rest/v1/trips','/rest/v1/audit_logs',
    '/storage/v1/object/authenticated/' + bucket + '/'];
  const post = ['/auth/v1/token','/rest/v1/rpc/get_authorized_trip_records',
    '/rest/v1/rpc/get_authorized_route_records','/storage/v1/object/list/' + bucket,
    '/storage/v1/object/sign/' + bucket + '/'];
  return (method === 'GET' ? get : method === 'POST' ? post : [])
    .some((item) => item === path || (item.endsWith('/') && path.startsWith(item)));
}
async function http(method, path, opts = {}) {
  if (!isAllowed(method, path)) throw Error('Non-allowlisted operation refused.');
  const url = new URL(path, base);
  if (url.protocol !== 'https:' || url.host !== host)
    throw Error('Non-Production HTTPS endpoint refused.');
  for (const [k,v] of Object.entries(opts.query || {})) url.searchParams.set(k,v);
  const headers = { apikey: publicKey(), Accept: 'application/json' };
  if (opts.jwt) headers.Authorization = 'Bearer ' + opts.jwt;
  if (opts.data !== undefined) headers['Content-Type'] = 'application/json';
  const res = await fetch(url, { method, headers,
    body: opts.data === undefined ? undefined : JSON.stringify(opts.data),
    signal: AbortSignal.timeout(15000), redirect: 'manual' });
  if (opts.binary) {
    // Inspect status only; never read or persist private document bytes.
    if (res.body) await res.body.cancel();
    return { status: res.status };
  }
  const body = await res.text();
  let json = null;
  try { json = body ? JSON.parse(body) : null; } catch (_) {}
  return { status: res.status, json };
}
async function signIn(email, password) {
  const r = await http('POST', '/auth/v1/token', { query:{grant_type:'password'},
    data: {email,password} });
  const jwt = r.json?.access_token, id = r.json?.user?.id;
  if (r.status !== 200 || typeof jwt !== 'string' || !uuid.test(id || ''))
    throw Error('GoTrue signed-JWT sign-in failed.');
  const verified = await http('GET','/auth/v1/user',{jwt});
  if (verified.status !== 200 || verified.json?.id !== id)
    throw Error('Signed JWT user identity not verified by GoTrue.');
  return { id, jwt };
}
async function table(name, jwt, query) {
  const r = await http('GET','/rest/v1/' + name,{jwt,query});
  if (r.status !== 200 || !Array.isArray(r.json))
    throw Error('Authorized table preflight failed: ' + name);
  return r.json;
}
async function tableDenied(name, jwt, company) {
  const r = await http('GET','/rest/v1/' + name,{jwt,
    query:{select:'id',company_id:'eq.' + company,limit:'1'}});
  return (r.status === 200 && Array.isArray(r.json) && r.json.length === 0)
    || r.status === 401 || r.status === 403;
}
function storagePath(operation, fullPath) {
  return '/storage/v1/object/' + operation + '/' + bucket + '/'
    + fullPath.split('/').map(encodeURIComponent).join('/');
}
async function findPrivateObject(jwt, companyIds) {
  const queue = [...companyIds], explored = new Set();
  while (queue.length && explored.size < 40) {
    const prefix = queue.shift();
    if (explored.has(prefix)) continue;
    explored.add(prefix);
    const r = await http('POST','/storage/v1/object/list/' + bucket,
      {jwt,data:{prefix,limit:100,offset:0}});
    if (r.status !== 200 || !Array.isArray(r.json))
      throw Error('Owner cannot list existing private Storage fixture.');
    for (const item of r.json) {
      if (typeof item?.name !== 'string' || !item.name || item.name.includes('/')) continue;
      const full = prefix + '/' + item.name;
      if (!companyIds.some((id) => full.startsWith(id + '/'))) continue;
      if (item.id) return full;
      if (item.id === null && queue.length < 40) queue.push(full);
    }
  }
  throw Error('No existing accessible Storage file: INCONCLUSIVE, no PASS.');
}
function hidden(prompt) {
  if (!stdin.isTTY || !stdin.setRawMode)
    return Promise.reject(Error('Interactive terminal required for hidden password input.'));
  stdout.write(prompt);
  return new Promise((resolve,reject) => {
    let secret = '';
    function finish() {
      stdin.off('data', onData); stdin.setRawMode(false); stdin.pause();
      stdout.write('\n');
    }
    function onData(chunk) {
      for (const c of chunk.toString('utf8')) {
        if (c === '\r' || c === '\n') { finish(); resolve(secret); return; }
        if (c === '\u0003') { finish(); reject(Error('Cancelled.')); return; }
        if (c === '\u007f' || c === '\b') secret = secret.slice(0,-1);
        else if (c >= ' ') secret += c;
      }
    }
    stdin.setRawMode(true); stdin.resume(); stdin.on('data',onData);
  });
}
async function run() {
  const mode = process.argv[2];
  if (process.argv.length !== 3 || !['--preflight','--execute'].includes(mode))
    throw Error('Usage: node script.js --preflight | --execute');
  pass(Number(process.versions.node.split('.')[0]) >= 22, 'Node 22+');
  publicKey();
  pass(true,'only publishable or anon API key accepted');
  pass(base === 'https://rkhmfbxlduuovlbsxhgy.supabase.co',
    'host locked to approved HTTPS Production project');
  if (mode === '--preflight') {
    stdout.write('PREFLIGHT ONLY; zero network requests or sign-ins.\n');
    return;
  }
  if (!stdin.isTTY) throw Error('Interactive terminal required.');
  const rl = readline.createInterface({input:stdin,output:stdout});
  let authorizedEmail, nonmemberEmail;
  try {
    authorizedEmail = (await rl.question('QA Owner/Admin email: ')).trim();
    nonmemberEmail = (await rl.question('Separate nonmember test user email: ')).trim();
  } finally { rl.close(); }
  if (!authorizedEmail.includes('@') || !nonmemberEmail.includes('@') ||
    authorizedEmail.toLowerCase() === nonmemberEmail.toLowerCase())
    throw Error('Distinct QA accounts required.');
  const authorizedPassword = await hidden('QA Owner/Admin password (hidden): ');
  const nonmemberPassword = await hidden('Nonmember password (hidden): ');
  const owner = await signIn(authorizedEmail,authorizedPassword);
  const outsider = await signIn(nonmemberEmail,nonmemberPassword);
  pass(owner.id !== outsider.id, 'two real distinct GoTrue signed JWT sessions');
  const memberRows = await table('company_users',owner.jwt,
    {select:'company_id,is_active',user_id:'eq.' + owner.id,is_active:'eq.true'});
  const companies = [...new Set(memberRows.map((row) => row.company_id))]
    .filter((id) => typeof id === 'string' && uuid.test(id));
  pass(companies.length === 2,'operator member of both existing QA tenants');
  const operatorCheck = await table('company_users',owner.jwt,
    {select:'company_id',user_id:'eq.' + outsider.id});
  pass(operatorCheck.every((r) => !companies.includes(r.company_id)),
    'operator confirms nonmember identity has no membership');
  const outsiderCheck = await table('company_users',outsider.jwt,
    {select:'company_id',user_id:'eq.' + outsider.id});
  pass(outsiderCheck.length === 0,'nonmember JWT sees zero own memberships');
  let trip = null,route = null;
  for (const company of companies) {
    const ownerTrips = await table('trips',owner.jwt,
      {select:'id',company_id:'eq.' + company,limit:'1'});
    const ownerRoutes = await table('routes',owner.jwt,
      {select:'id',company_id:'eq.' + company,limit:'1'});
    if (ownerTrips.length && !trip) trip = {company,id:ownerTrips[0].id};
    if (ownerRoutes.length && !route) route = {company,id:ownerRoutes[0].id};
    pass(await tableDenied('trips',outsider.jwt,company),
      'nonmember cannot list target company Trips');
    pass(await tableDenied('routes',outsider.jwt,company),
      'nonmember cannot list target company Routes');
    pass(await tableDenied('audit_logs',outsider.jwt,company),
      'nonmember cannot list target company Audit events');
  }
  pass(trip !== null && route !== null,'positive Trip and Route fixtures exist');
  const blockedTrip = await http('POST','/rest/v1/rpc/get_authorized_trip_records',
    {jwt:outsider.jwt,data:{p_company_id:trip.company,p_trip_id:trip.id,p_active_only:false}});
  pass(blockedTrip.status >= 400 && blockedTrip.status < 500 &&
    blockedTrip.json?.code === 'P3433','secured Trip projection denies nonmember');
  const blockedRoute = await http('POST','/rest/v1/rpc/get_authorized_route_records',
    {jwt:outsider.jwt,data:{p_company_id:route.company,p_route_id:route.id,p_active_only:false}});
  pass(blockedRoute.status >= 400 && blockedRoute.status < 500 &&
    blockedRoute.json?.code === 'P3434','secured Route projection denies nonmember');
  const file = await findPrivateObject(owner.jwt,companies);
  pass(true,'existing owner-visible private Storage object found');
  const ownerGet = await http('GET',storagePath('authenticated',file),
    {jwt:owner.jwt,binary:true});
  pass([200,206].includes(ownerGet.status),
    'owner download authorization control succeeds; bytes discarded');
  const strangerGet = await http('GET',storagePath('authenticated',file),
    {jwt:outsider.jwt,binary:true});
  pass([400,401,403,404].includes(strangerGet.status),
    'nonmember cannot download private object');
  const anonGet = await http('GET',storagePath('authenticated',file),{binary:true});
  pass([400,401,403,404].includes(anonGet.status),
    'anonymous cannot download private object');
  const ownerSign = await http('POST',storagePath('sign',file),
    {jwt:owner.jwt,data:{expiresIn:60}});
  pass(ownerSign.status === 200 &&
    typeof (ownerSign.json?.signedURL || ownerSign.json?.signedUrl) === 'string',
    'owner can mint a short-lived private URL; URL never disclosed');
  const outsiderSign = await http('POST',storagePath('sign',file),
    {jwt:outsider.jwt,data:{expiresIn:60}});
  pass([400,401,403,404].includes(outsiderSign.status),
    'nonmember cannot mint a private Storage signed URL');
  stdout.write('SUMMARY: ' + passCount + ' PASS / 0 FAIL. NO BUSINESS MUTATIONS.\n');
  stdout.write('Delete the disposable nonmember Auth account in Dashboard after this test.\n');
}
run().catch((error) => {
  const msg = String(error?.message || 'unexpected failure');
  const safe = /^(FAIL |Usage:|Node |A publishable|Invalid anon|Refusing |Non-allowlisted|Non-Production|GoTrue|Signed JWT|Authorized table|Owner cannot|No existing|Interactive|Distinct|Cancelled)/.test(msg);
  stderr.write((safe ? msg : 'BLOCKED: unexpected test failure') + '\n');
  stderr.write('SUMMARY: ' + passCount + ' PASS / 1 BLOCKED. NO RELEASE PASS.\n');
  process.exitCode = 1;
});
