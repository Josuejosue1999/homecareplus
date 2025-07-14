# API Configuration Guide

## Environment Variables

To use the AI Chat feature and other services, you need to configure the following environment variables:

### OpenAI API Configuration
```bash
# Set this environment variable for AI Chat functionality
OPENAI_API_KEY=your-openai-api-key-here
```

### Running the App with Environment Variables

#### Flutter Development
```bash
# Set environment variable before running
export OPENAI_API_KEY="your-actual-openai-api-key"
flutter run --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY
```

#### Production Build
```bash
# Android
flutter build apk --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY

# iOS
flutter build ios --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY
```

### Security Notes
- Never commit API keys directly to version control
- Use environment variables or secure configuration management
- The app will show a configuration message if API key is not set
- API keys should be kept secure and rotated regularly

### Other Required APIs
- Google Maps API (for location services)
- Firebase (for authentication and database)
- Google Places API (for hospital search)

## Development Setup
1. Obtain API keys from respective services
2. Set environment variables in your development environment
3. Use `--dart-define` flags when running Flutter commands
4. Ensure all team members have proper API access 