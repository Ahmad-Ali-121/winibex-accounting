// Receipt uploads.
//
// Files are written to disk outside the web root and served only through an
// authenticated route, so nobody can fetch a receipt by guessing a URL. The
// database holds the record; the disk holds the bytes. Decision 033.
//
// Three things here are deliberate and should not be relaxed:
//
//   The name on disk is random. Using the uploaded name would let someone
//   send "../../.env" and decide where the file lands.
//
//   The type is decided by what the browser claims AND by the extension we
//   give it, from a short allow list. A receipt is a photo or a PDF.
//
//   The size limit is enforced by multer before anything reaches disk, so a
//   large upload is refused rather than filling the server.

import { createHash, randomBytes } from 'node:crypto';
import { createReadStream } from 'node:fs';
import { mkdir, readFile, unlink } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

import multer from 'multer';

import { badRequest, ErrorCode } from './errors.js';

export const MAX_UPLOAD_MB = 10;
export const MAX_UPLOAD_BYTES = MAX_UPLOAD_MB * 1024 * 1024;

// What a receipt can be. A phone photo or a PDF from a bank.
const ALLOWED = new Map([
  ['image/jpeg', '.jpg'],
  ['image/png', '.png'],
  ['image/webp', '.webp'],
  ['image/heic', '.heic'],
  ['application/pdf', '.pdf'],
]);

export function uploadRoot() {
  const configured = process.env.UPLOAD_DIR;
  if (!configured) {
    throw new Error(
      'UPLOAD_DIR is not set. Receipts must be stored outside the web root; see docs/DEPLOY.md.',
    );
  }
  return configured;
}

// Receipts live under a year and month, so a folder never grows past a few
// hundred files and a restore from backup can be partial.
export function folderFor(date = new Date()) {
  const year = String(date.getUTCFullYear());
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  return path.join(uploadRoot(), 'receipts', year, month);
}

const storage = multer.diskStorage({
  destination: (req, file, callback) => {
    const folder = folderFor();
    mkdir(folder, { recursive: true })
      .then(() => callback(null, folder))
      .catch(callback);
  },
  filename: (req, file, callback) => {
    const extension = ALLOWED.get(file.mimetype) ?? '';
    callback(null, `${randomBytes(16).toString('hex')}${extension}`);
  },
});

export const receiptUpload = multer({
  storage,
  limits: { fileSize: MAX_UPLOAD_BYTES, files: 1 },
  fileFilter: (req, file, callback) => {
    if (!ALLOWED.has(file.mimetype)) {
      callback(
        badRequest(
          ErrorCode.UNSUPPORTED_FILE,
          'A receipt has to be a photo or a PDF.',
          { field: 'file' },
        ),
      );
      return;
    }
    callback(null, true);
  },
});

/// The fingerprint of what was stored, so a later copy can be proved identical
/// to the one that was uploaded.
export async function hashFile(absolutePath) {
  const contents = await readFile(absolutePath);
  return createHash('sha256').update(contents).digest('hex');
}

export function streamFile(absolutePath) {
  return createReadStream(absolutePath);
}

// Only used when the database write fails after the file has landed. A file
// with no record is invisible and would never be cleaned up otherwise.
export async function discard(absolutePath) {
  try {
    await unlink(absolutePath);
  } catch {
    // Already gone, or never written. Either way there is nothing to do.
  }
}

/// The path relative to UPLOAD_DIR, which is what the database stores. An
/// absolute path would break the day the server moves.
export function relativeTo(absolutePath) {
  return path.relative(uploadRoot(), absolutePath).split(path.sep).join('/');
}

export function absoluteFrom(relativePath) {
  const resolved = path.resolve(uploadRoot(), relativePath);

  // A stored path should never climb out of the upload folder. If one does,
  // something has written a value nothing in this code produces.
  if (!resolved.startsWith(path.resolve(uploadRoot()))) {
    throw new Error('Refusing to read a file outside the upload folder');
  }
  return resolved;
}
