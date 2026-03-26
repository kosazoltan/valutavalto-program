const { Client } = require('pg');
const c = new Client('postgresql://neondb_owner:npg_vUByfDYK39QH@ep-hidden-bread-ag06kat1-pooler.c-2.eu-central-1.aws.neon.tech/neondb?sslmode=require');

async function run() {
  await c.connect();
  
  // List all tables
  const tables = await c.query("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name");
  console.log('TABLES:', tables.rows.map(r => r.table_name).join(', '));
  
  // Flyway
  try {
    const f = await c.query("SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 10");
    console.log('FLYWAY:', JSON.stringify(f.rows, null, 2));
  } catch(e) {
    console.log('NO flyway_schema_history:', e.message);
  }
  
  await c.end();
}
run().catch(e => { console.error(e.message); c.end(); });
