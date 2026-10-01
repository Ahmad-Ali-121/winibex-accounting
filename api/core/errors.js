// One error shape for the whole API, as in docs/API.md:
//
//   { "error": { "code", "message", "field", "details" } }
//
// `code` is stable and machine-readable. `message` is safe to show a user, so
// it never contains a stack trace, a SQL fragment or a file path.

export const ErrorCode = {
  BAD_REQUEST: 'BAD_REQUEST',
  MALFORMED_JSON: 'MALFORMED_JSON',
  PAYLOAD_TOO_LARGE: 'PAYLOAD_TOO_LARGE',
  VALIDATION_FAILED: 'VALIDATION_FAILED',
  INVALID_CREDENTIALS: 'INVALID_CREDENTIALS',
  ACCOUNT_INACTIVE: 'ACCOUNT_INACTIVE',
  NOT_AUTHENTICATED: 'NOT_AUTHENTICATED',
  TOKEN_EXPIRED: 'TOKEN_EXPIRED',
  TOKEN_INVALID: 'TOKEN_INVALID',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  RATE_LIMITED: 'RATE_LIMITED',
  IDEMPOTENCY_KEY_REQUIRED: 'IDEMPOTENCY_KEY_REQUIRED',
  IDEMPOTENCY_KEY_INVALID: 'IDEMPOTENCY_KEY_INVALID',
  IDEMPOTENCY_KEY_REUSED: 'IDEMPOTENCY_KEY_REUSED',
  REQUEST_IN_PROGRESS: 'REQUEST_IN_PROGRESS',
  DATABASE_UNAVAILABLE: 'DATABASE_UNAVAILABLE',
  INTERNAL: 'INTERNAL',
};

export class AppError extends Error {
  constructor(status, code, message, { field = null, details = null } = {}) {
    super(message);
    this.name = 'AppError';
    this.status = status;
    this.code = code;
    this.field = field;
    this.details = details;
  }
}

export const badRequest = (code, message, extra) => new AppError(400, code, message, extra);
export const unauthorized = (code, message) => new AppError(401, code, message);
export const forbidden = (message) => new AppError(403, ErrorCode.FORBIDDEN, message);
export const notFound = (message = 'Not found.') => new AppError(404, ErrorCode.NOT_FOUND, message);

export function notFoundHandler(req, res, next) {
  next(notFound(`No route for ${req.method} ${req.path}.`));
}

// Express 5 forwards a rejected async handler here on its own, which is why
// route handlers are plain async functions with no wrapper.
// Express and its body parser throw their own errors for a malformed request.
// Those are the caller's mistake, not ours, so they must not be reported as a
// server failure or logged as if something broke.
function asAppError(error) {
  if (error instanceof AppError) return error;

  if (error?.type === 'entity.parse.failed') {
    return badRequest(ErrorCode.MALFORMED_JSON, 'The request body is not valid JSON.');
  }
  if (error?.type === 'entity.too.large') {
    return new AppError(413, ErrorCode.PAYLOAD_TOO_LARGE, 'That request is too large.');
  }
  // Anything else that already carries a client status and says it is safe to
  // show, such as a bad Content-Type.
  if (error?.expose === true && error.status >= 400 && error.status < 500) {
    return new AppError(error.status, ErrorCode.BAD_REQUEST, error.message);
  }

  return null;
}

// eslint-disable-next-line no-unused-vars
export function errorHandler(error, req, res, next) {
  const known = asAppError(error);

  if (!known) {
    // Log the real thing, return nothing revealing.
    console.error('Unhandled error:', error);
  }

  res.status(known ? known.status : 500).json({
    error: {
      code: known ? known.code : ErrorCode.INTERNAL,
      message: known ? known.message : 'Something went wrong on our side.',
      field: known ? known.field : null,
      details: known ? known.details : null,
    },
  });
}

// Turns a zod failure into the same shape, naming the first offending field.
export function fromZod(result) {
  const issue = result.error.issues[0];
  return badRequest(
    ErrorCode.VALIDATION_FAILED,
    issue.message,
    { field: issue.path.join('.') || null },
  );
}

export function parseOrThrow(schema, value) {
  const result = schema.safeParse(value);
  if (!result.success) throw fromZod(result);
  return result.data;
}
