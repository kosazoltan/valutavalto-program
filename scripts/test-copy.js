const fs = require('fs');
try {
  fs.copyFileSync(
    'D:\\repo\\valutavalto-program\\backend\\target\\valuta-backend-1.0.0-SNAPSHOT.jar',
    'C:\\ProgramData\\BestChange\\backend\\valuta-backend.jar'
  );
  console.log('COPY OK');
} catch(e) {
  console.log('COPY FAIL:', e.code, e.message.slice(0,150));
}
