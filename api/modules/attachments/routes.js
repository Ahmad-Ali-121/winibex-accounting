import { Router } from 'express';
import { z } from 'zod';

import { parseOrThrow, badRequest, ErrorCode } from '../../core/errors.js';
import { requireAuth } from '../../core/auth.js';
import { receiptUpload, MAX_UPLOAD_MB } from '../../core/uploads.js';
import * as service from './service.js';

export const attachmentRoutes = Router();

const idParam = z.object({ id: z.coerce.number().int().positive() });

const typeField = z.object({
  documentType: z
    .enum(['receipt', 'bank_advice', 'bank_statement', 'tax_certificate',
           'invoice_received', 'contract', 'other'])
    .optional(),
});

// multer reports a file over the limit as its own error type. Turning it into
// the standard error shape means the app gets a code it already understands
// rather than a 500.
function handleUploadErrors(error, req, res, next) {
  if (error?.code === 'LIMIT_FILE_SIZE') {
    next(badRequest(
      ErrorCode.FILE_TOO_LARGE,
      `A receipt has to be under ${MAX_UPLOAD_MB} MB.`,
      { field: 'file' },
    ));
    return;
  }
  next(error);
}

attachmentRoutes.get('/transactions/:id/attachments', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  res.json(await service.listFor(id));
});

attachmentRoutes.post(
  '/transactions/:id/attachments',
  requireAuth,
  receiptUpload.single('file'),
  handleUploadErrors,
  async (req, res) => {
    const { id } = parseOrThrow(idParam, req.params);
    const body = parseOrThrow(typeField, req.body ?? {});

    const attachment = await service.attach({
      user: { id: Number(req.user.id), role: req.user.role },
      transactionId: id,
      file: req.file,
      documentType: body.documentType ?? 'receipt',
      ip: req.ip,
    });

    res.status(201).json({ attachment });
  },
);

// Receipts live outside the web root, so this is the only way to read one and
// it needs a login. A static folder would let anyone with the URL fetch a
// supplier invoice.
attachmentRoutes.get('/attachments/:id/file', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  const file = await service.openFile(id);

  res.setHeader('Content-Type', file.mime);
  res.setHeader('Content-Length', file.sizeBytes);
  res.setHeader('Content-Disposition', 'inline');
  file.stream.pipe(res);
});
