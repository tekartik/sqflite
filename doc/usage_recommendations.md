Below are (or will be) personal recommendations on usage

## Single database connection

The API is largely inspired from Android ContentProvider where a typical SQLite implementation means
opening the database once on the first request and keep it open

Personally I have one global reference Database in my flutter application to avoid lock issues. Opening the
database should be safe if called multiple time.

Keeping a reference only in a widget can cause issues with hot reload if the reference is lost (and the database not
closed yet).
