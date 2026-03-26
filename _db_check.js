const { Client } = require('pg');
const c = new Client('postgresql://neondb_owner:npg_vUByfDYK39QH@ep-hidden-bread-ag06kat1-pooler.c-2.eu-central-1.aws.neon.tech/neondb?sslmode=require');

async function run() {
  await c.connect();
  
  // Check worker BORSI
  const w = await c.query("SELECT w.id, w.code, w.name, w.role, w.branch_id, b.code as branch_code, c.code as company_code FROM worker w LEFT JOIN branch b ON w.branch_id = b.id LEFT JOIN company c ON w.company_id = c.id WHERE w.code = 'BORSI'");
  console.log('WORKER BORSI:', JSON.stringify(w.rows, null, 2));
  
  // Check token_blacklist table exists
  const t = await c.query("SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'token_blacklist')");
  console.log('token_blacklist table:', t.rows[0].exists);
  
  // Check flyway version
  const f = await c.query("SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 5");
  console.log('Flyway latest:', JSON.stringify(f.rows, null, 2));
  
  await c.end();
}
run().catch(e => { console.error(e.message); c.end(); });
