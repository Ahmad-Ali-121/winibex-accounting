// Generates a password hash locally.
//
// Hostinger has no migration CLI, so the owner's first password cannot be set
// by the application. It is hashed here and pasted into the seed SQL in
// phpMyAdmin, with must_change_password = 1 so it is replaced on first login.
//
//   npm run hash:password
//
// The password is read from stdin and masked, so it never reaches shell
// history or the process list. Nothing is written to a file.

import readline from 'node:readline';
import process from 'node:process';
import { hashPassword, verifyPassword, configuredAlgorithm, passwordPolicy } from '../core/password.js';

function askMasked(question) {
  return new Promise((resolve, reject) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      terminal: true,
    });

    let masking = false;
    const originalWrite = rl._writeToOutput.bind(rl);
    rl._writeToOutput = (text) => {
      if (!masking) {
        originalWrite(text);
        return;
      }
      if (text.includes('\n')) process.stdout.write('\n');
    };

    rl.question(question, (answer) => {
      masking = false;
      rl.close();
      resolve(answer);
    });
    rl.on('error', reject);
    masking = true;
  });
}

const algorithm = configuredAlgorithm();
console.log(`Algorithm: ${algorithm}`);
console.log(`Minimum length: ${passwordPolicy.minLength} characters\n`);

const first = await askMasked('Password: ');
const second = await askMasked('Repeat:   ');

if (first !== second) {
  console.error('\nThe two entries do not match. Nothing was generated.');
  process.exit(1);
}

let hash;
try {
  hash = await hashPassword(first);
} catch (error) {
  console.error(`\n${error.message}`);
  process.exit(1);
}

// Prove the hash before it is pasted anywhere. A hash that does not verify is
// a locked account on a system with no password reset flow yet.
const verified = await verifyPassword(hash, first);
if (!verified) {
  console.error('\nThe generated hash did not verify. Do not use it.');
  process.exit(1);
}

console.log('\nVerified. Hash:\n');
console.log(hash);
console.log('\nPaste this into the users seed as password_hash, with must_change_password = 1.');
