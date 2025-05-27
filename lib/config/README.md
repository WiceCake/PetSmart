# Configuration Setup

## Security Notice
**NEVER commit `local_config.dart` to Git!** This file contains sensitive credentials.

## Setup Instructions

### For Development:
1. Copy `local_config.dart.example` to `local_config.dart`
2. Add your actual Supabase credentials to `local_config.dart`
3. The file is already in `.gitignore` and won't be committed

### For Production:
Use environment variables during build:
```bash
flutter build apk --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

### Configuration Priority:
1. Environment variables (production builds)
2. Local config file (development)
3. Empty/demo mode (graceful fallback)

## Files:
- `app_config.dart` - Main configuration handler (safe to commit)
- `local_config.dart.example` - Template file (safe to commit)
- `local_config.dart` - Your actual credentials (DO NOT COMMIT!)
