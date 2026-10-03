/// Retry policy for providers that read from the API.
///
/// Riverpod 3 retries a failed provider by itself, with a backoff. That is the
/// wrong default here for two reasons.
///
/// A 403 or a 409 will not become a 200 by asking again, so retrying only
/// delays telling the person what happened. And while a retry is in flight the
/// provider is loading rather than failed, so the screen shows a skeleton and
/// the person waits without being told anything is wrong.
///
/// A read that fails shows an error panel with a Try again button. The person
/// decides. Writes are never retried automatically at all: they carry an
/// idempotency key for the case where the answer was lost rather than the
/// request, see docs/API.md.
library;

/// Never retry. Used by every read provider in the app.
Duration? noRetry(int retryCount, Object error) => null;
