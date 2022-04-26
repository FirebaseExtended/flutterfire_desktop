///
///Domain name for firebase storage.
///
const DEFAULT_HOST = 'firebasestorage.googleapis.com';

///
///The key in Firebase config json for the storage bucket.
///
const CONFIG_STORAGE_BUCKET_KEY = 'storageBucket';

///
///2 minutes
///
///The timeout for all operations except upload.
///
const DEFAULT_MAX_OPERATION_RETRY_TIME = 2 * 60 * 1000;

///
///10 minutes
///
///The timeout for upload.
///
const DEFAULT_MAX_UPLOAD_RETRY_TIME = 10 * 60 * 1000;

///
///This is the value of Number.MIN_SAFE_INTEGER, which is not well supported
///enough for us to use it directly.
///
const MIN_SAFE_INTEGER = -9007199254740991;
