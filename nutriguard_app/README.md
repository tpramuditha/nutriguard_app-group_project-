# NutriGuard – AI Food Nutrition & Meal Advisor

NutriGuard is a Flutter-based mobile application designed to help users understand their food intake, manage nutrition, and make better meal decisions through AI-assisted food recognition and personalized recommendations.

## Features

- **AI Food Recognition** – Identify food items from images using an AI-powered backend.
- **Nutrition Analysis** – View calories, protein, carbohydrates, and fat.
- **Meal Recommendations** – Discover meal suggestions based on nutrition and available ingredients.
- **Meal Planner** – Plan and manage daily meals.
- **Food History** – Track previously logged meals.
- **Health Profile** – Manage health reports and monthly health markers.
- **My Pantry** – Manage ingredients and quantities available at home.
- **Exercise Recommendations** – Receive exercise suggestions based on fitness goals and preferences.
- **Progress Tracking** – Monitor nutrition, weight, and activity progress.
- **Data Export** – Export personal application data as a CSV file.
- **Profile & Privacy** – Manage account settings, preferences, and personal data.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Mobile application development |
| Dart | Application programming language |
| Firebase Authentication | User authentication |
| Cloud Firestore | Cloud database |
| Groq API | AI food recognition |
| Node.js | AI backend |
| Express.js | Backend API |
| Google ML Kit | On-device text recognition |
| Git & GitHub | Version control |

## Project Structure

```text
nutriguard_app/
├── android/
├── backend/
│   ├── server.js
│   ├── package.json
│   └── .env.example
├── firestore.rules
├── lib/
│   ├── app/
│   ├── core/
│   └── features/
├── test/
├── pubspec.yaml
└── README.md
```

## Requirements

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Android Emulator or Android device
- Node.js and npm
- Firebase project
- Groq API key

## Installation and Setup

### 1. Clone the Repository

```bash
git clone https://github.com/tpramuditha/nutriguard_app.git
cd nutriguard_app
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Configure your Firebase project and add the required FlutterFire configuration files.

Enable:
- Firebase Authentication – Email/Password
- Cloud Firestore

### 4. Configure the AI Backend

Navigate to the backend directory:

```bash
cd backend
npm install
```

Create a `.env` file using `.env.example` as a reference.

Add your own Groq API key:

```env
GROQ_API_KEY=your_actual_groq_api_key
PORT=3000
```

Never commit your actual `.env` file or API key to GitHub.

Start the backend:

```bash
node server.js
```

### 5. Run the Application

For Android Emulator, configure the backend connection as required. If using the current `127.0.0.1:3000` emulator setup, enable ADB reverse:

```bash
adb reverse tcp:3000 tcp:3000
```

Then run:

```bash
flutter run
```

## Testing

Run Flutter tests:

```bash
flutter test
```

Analyze the project:

```bash
flutter analyze
```

## Release Build

Generate an Android release APK:

```bash
flutter build apk --release
```

The generated APK is available at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Security

- Firebase Firestore security rules enforce user-specific access.
- Backend API credentials are stored in environment variables.
- Local environment files and Node.js dependencies are excluded from Git.
- Personal data access is restricted through authenticated user ownership checks.

## Disclaimer

NutriGuard provides nutrition information and AI-assisted suggestions for informational purposes. It is not a replacement for professional medical advice, diagnosis, or treatment.


Email-thathsarapramuditha11@gmail.com
p-12345678