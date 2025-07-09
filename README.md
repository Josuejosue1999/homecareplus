# HomeCare Plus - Healthcare Application

HomeCare Plus is a comprehensive healthcare application built with Flutter for mobile and Node.js for web services. It provides patients with easy access to healthcare services, appointment booking, real-time chat with healthcare providers, and AI-powered health assistance.

## 🌟 Features

### Patient Features
- **🏥 Hospital Discovery**: Find nearby hospitals and clinics with Google Maps integration
- **📅 Appointment Booking**: Schedule appointments with healthcare providers
- **💬 Real-time Chat**: Communicate with healthcare providers instantly
- **🤖 AI Health Assistant**: Get health information and guidance from Dr. AI
- **📱 Mobile App**: Native Android and iOS applications
- **🔐 Secure Authentication**: Firebase-based authentication system
- **📍 Location Services**: GPS-based location detection and mapping
- **🔔 Push Notifications**: Real-time notifications for appointments and messages

### Healthcare Provider Features
- **📊 Professional Dashboard**: Manage appointments, patients, and communications
- **👥 Patient Management**: View patient information and history
- **📈 Analytics**: Track appointments, patient interactions, and performance
- **💬 Chat System**: Secure messaging with patients
- **📅 Schedule Management**: Manage availability and appointments

### Admin Features
- **🎛️ Admin Dashboard**: Professional dashboard with modern UI
- **📊 Statistics & Analytics**: Real-time data visualization with Chart.js
- **👥 User Management**: Manage patients and healthcare providers
- **🔍 Search & Filter**: Advanced search functionality
- **📱 Responsive Design**: Works on desktop and mobile devices

## 🚀 Technology Stack

### Frontend
- **Flutter**: Cross-platform mobile application
- **Dart**: Programming language for Flutter
- **Firebase**: Authentication and real-time database
- **Google Maps API**: Location services and mapping

### Backend
- **Node.js**: Server-side JavaScript runtime
- **Express.js**: Web application framework
- **Socket.IO**: Real-time communication
- **Firebase Admin SDK**: Server-side Firebase integration
- **Morgan**: HTTP request logging

### Database
- **Firestore**: NoSQL document database
- **Firebase Storage**: File storage for images and documents

### External APIs
- **OpenAI GPT**: AI-powered health assistant
- **Google Maps API**: Location and mapping services
- **Firebase Cloud Messaging**: Push notifications

## 📦 Installation

### Prerequisites
- Node.js (v14 or higher)
- Flutter SDK (v3.0 or higher)
- Firebase account
- Google Cloud Platform account (for Maps API)
- OpenAI API key (for AI features)

### 1. Clone the Repository
```bash
git clone https://github.com/Josuejosue1999/homecareplus.git
cd homecareplus
```

### 2. Environment Configuration
Copy the environment example file and configure your API keys:

```bash
cp env.example .env
```

Edit the `.env` file with your actual API keys:

```bash
# OpenAI API Key for AI Chat Feature
OPENAI_API_KEY=your-openai-api-key-here

# Firebase Configuration
FIREBASE_API_KEY=your-firebase-api-key
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
FIREBASE_APP_ID=your-app-id

# Google Maps API Key
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

### 3. Backend Setup
Install Node.js dependencies:

```bash
npm install
```

Start the main server (port 3000):
```bash
npm start
```

Start the admin dashboard (port 4000):
```bash
cd admin-dashboard
npm install
npm start
```

### 4. Flutter Mobile App Setup
Install Flutter dependencies:

```bash
flutter pub get
```

Run the mobile app:
```bash
flutter run
```

## 🔧 Configuration

### Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication, Firestore, and Cloud Messaging
3. Download the configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
4. Place these files in their respective directories

### Google Maps API Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Maps JavaScript API and Places API
3. Create an API key and add it to your `.env` file
4. Configure API restrictions for security

### OpenAI API Setup
1. Sign up at [OpenAI](https://openai.com/)
2. Generate an API key
3. Add the key to your `.env` file
4. Configure usage limits and billing

## 🏃‍♂️ Running the Application

### Development Mode
1. Start the backend server:
   ```bash
   npm start
   ```

2. Start the admin dashboard:
   ```bash
   cd admin-dashboard
   npm start
   ```

3. Run the Flutter app:
   ```bash
   flutter run
   ```

### Production Deployment
1. Build the Flutter app:
   ```bash
   flutter build apk --release
   ```

2. Deploy the backend to your preferred hosting service
3. Configure environment variables on your hosting platform

## 📱 App Usage

### For Patients
1. **Register/Login**: Create an account or sign in
2. **Find Healthcare**: Search for nearby hospitals and clinics
3. **Book Appointments**: Schedule appointments with healthcare providers
4. **Chat with Providers**: Communicate with healthcare professionals
5. **AI Assistant**: Get health information from Dr. AI

### For Healthcare Providers
1. **Dashboard Access**: Log in to the professional dashboard
2. **Manage Appointments**: View and manage patient appointments
3. **Patient Communication**: Chat with patients securely
4. **Profile Management**: Update clinic information and services

### For Administrators
1. **Admin Dashboard**: Access the admin panel at `http://localhost:4000`
2. **User Management**: Manage patients and healthcare providers
3. **Analytics**: View system statistics and performance
4. **System Configuration**: Configure application settings

## 🔒 Security Features

- **Firebase Authentication**: Secure user authentication
- **Environment Variables**: Sensitive data stored securely
- **API Key Protection**: Keys not exposed in client-side code
- **Data Encryption**: Secure data transmission
- **Input Validation**: Protection against malicious inputs

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Commit your changes: `git commit -am 'Add new feature'`
4. Push to the branch: `git push origin feature/new-feature`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Contact the development team
- Check the documentation

## 🚀 Roadmap

- [ ] Video consultation feature
- [ ] Prescription management
- [ ] Health records integration
- [ ] Multi-language support
- [ ] Advanced analytics dashboard
- [ ] Payment integration
- [ ] Telemedicine features

## 🙏 Acknowledgments

- OpenAI for AI capabilities
- Google for Maps and Firebase services
- Flutter team for the amazing framework
- All contributors and testers

---

**HomeCare Plus** - Making healthcare accessible and convenient for everyone! 🏥✨


