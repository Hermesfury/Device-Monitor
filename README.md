# DevMonitor: Behavioral Intelligence & Security Monitoring Engine

A production-grade mobile monitoring system that transforms raw device metrics into actionable behavioral intelligence and security insights. Build with Flutter, Kotlin, and Node.js.

![DevMonitor Logo](./frontend/assets/Dev%20Monitor.png)

## 🚀 Overview

DevMonitor is an advanced monitoring engine designed to provide comprehensive visibility into device health, app usage, and security risks. It follows **Clean Architecture** principles and is designed for 100% local processing to ensure maximum privacy.

### Key Capabilities

*   **Behavioral Intelligence**: Deep analysis of app usage patterns and sessions.
*   **Anomaly Detection**: Real-time identification of CPU spikes, memory leaks, and unusual network activity.
*   **Risk Scoring**: Automated security evaluation of installed applications based on permissions and behavior.
*   **System Analytics**: Real-time tracking of CPU, RAM, Battery, Network, and Storage.
*   **Intelligence Reports**: Automated generation of weekly usage and security summaries.

## 🏗 Repository Structure

This repository is organized as a monorepo to support both the mobile engine and auxiliary services:

*   **/frontend**: The core mobile application (Flutter & Kotlin/Android).
    - Contains the native collectors, business logic, and UI.
*   **/backend**: A Node.js/Express template for report synchronization and centralized monitoring.
*   **/tests**: Comprehensive unit and widget tests for the monitoring logic.
*   **/CI_CD**: Deployment guides and GitHub Actions configurations.

## 🛠 Getting Started

This guide provides step-by-step instructions to clone, set up, build, and run DevMonitor on your local machine. DevMonitor is a Flutter-based mobile app that requires an Android device or emulator for full functionality, as it performs native Android monitoring operations.

### Prerequisites

Before you begin, ensure you have the following installed on your system:

1. **Flutter SDK (3.19.0 or later)**:
   - Download from the official Flutter website: https://flutter.dev/docs/get-started/install
   - Follow the installation instructions for your operating system (Windows, macOS, or Linux).
   - Verify installation by running `flutter doctor` in your terminal. This command checks for any missing dependencies and provides guidance on resolving them.

2. **Android Studio (or Android SDK)**:
   - Download Android Studio from: https://developer.android.com/studio
   - Install Android Studio, which includes the Android SDK (API 21+ required).
   - During installation, ensure you install the Android SDK and Android Virtual Device (AVD) manager.
   - Alternatively, if you prefer command-line only, you can install the Android SDK via Android Studio or manually.

3. **Java Development Kit (JDK)**:
   - Flutter requires JDK 11 or later.
   - Download from: https://adoptium.net/temurin/releases/ (recommended) or Oracle JDK.
   - Set the `JAVA_HOME` environment variable to point to your JDK installation.

4. **Node.js (18+)** and **npm** (for backend, optional):
   - Download Node.js from: https://nodejs.org/
   - npm is included with Node.js. Verify with `node --version` and `npm --version`.

5. **Git**:
   - Required to clone the repository. Download from: https://git-scm.com/downloads

6. **Android Device or Emulator**:
   - A physical Android device (API 21+) connected via USB with USB debugging enabled, or an Android Virtual Device (AVD) created in Android Studio.

### Step-by-Step Setup and Build Instructions

#### 1. Clone the Repository
```bash
git clone https://github.com/your-username/devmonitor.git  # Replace with actual repo URL
cd devmonitor
```

#### 2. Set Up Flutter Environment
- Open a terminal/command prompt.
- Run `flutter doctor` to verify your Flutter installation and identify any issues.
- If there are missing components (e.g., Android licenses), follow the prompts to accept licenses:
  ```bash
  flutter doctor --android-licenses
  ```
- Ensure your Android device/emulator is connected and recognized:
  ```bash
  flutter devices
  ```
- If using an emulator, start it from Android Studio's AVD Manager.

#### 3. Install Frontend Dependencies and Build the App
The frontend is a Flutter application that includes native Android collectors for monitoring device metrics.

```bash
# Navigate to the frontend directory
cd frontend

# Install Flutter dependencies
flutter pub get

# (Optional) Run tests to ensure everything is working
flutter test

# Build the APK for Android
flutter build apk --release

# Or run the app directly on a connected device/emulator
flutter run
```

- **Building APK**: The `flutter build apk --release` command generates a production-ready APK file in `build/app/outputs/flutter-apk/`. You can install this APK on your Android device.
- **Running Directly**: `flutter run` launches the app on your connected Android device or emulator.
- **Debug Mode**: For development, `flutter run` runs in debug mode by default, allowing hot reload.

#### 4. (Optional) Set Up and Run the Backend
The backend is a simple Node.js/Express server for report synchronization. It's optional and not required for basic app functionality.

```bash
# Navigate to the backend directory (from project root)
cd backend

# Install Node.js dependencies
npm install

# Start the server
npm start
```

- The server runs on `http://localhost:3000` by default (check `index.js` for port configuration).
- This backend can be used for syncing reports if you extend the app's functionality.

#### 5. Configure Device Permissions
DevMonitor requires specific Android permissions to monitor device metrics. After installing and launching the app:

1. **Enable Usage Access**: Go to Settings > Security > Usage Access > DevMonitor > Allow.
2. **Grant Battery Optimization Exemption**: Settings > Apps > DevMonitor > Battery > Don't optimize.
3. **Storage Permissions**: The app may request storage access for logging (grant as needed).
4. **Other Permissions**: The app will prompt for any additional permissions on first launch.

Without these permissions, the monitoring features will not function properly.

#### 6. Verify Installation
- Launch the app on your Android device/emulator.
- The dashboard should display real-time metrics for CPU, RAM, Battery, Network, and Storage.
- Navigate through the screens: Dashboard, History, and Permissions.
- Check the console/logs for any errors during runtime.

### Troubleshooting
- **Flutter Doctor Issues**: Run `flutter doctor -v` for detailed diagnostics and follow the suggested fixes.
- **Build Failures**: Ensure all prerequisites are installed and environment variables are set correctly.
- **Device Not Recognized**: Enable USB debugging on your device and accept the RSA key prompt.
- **Permission Issues**: Manually grant permissions in Android Settings as described above.
- **Emulator Problems**: Ensure your AVD is properly configured with API 21+ and has sufficient RAM/storage.

For more advanced deployment options, refer to the [Deployment Guide](./CI_CD/deployment_guide.md).

## 🔒 Security & Privacy

DevMonitor is built with privacy as its foundation:
- **Local-First**: All data collection and analysis happens on the device.
- **Transparent Permissions**: Requires granular access for monitoring (Usage Stats, Battery Stats, etc.) but discloses usage clearly.
- **End-to-End Control**: Users have full visibility into what is being monitored.

## 🏁 CI/CD

Automated linting and testing are handled via GitHub Actions. See the [Deployment Guide](./CI_CD/deployment_guide.md) for more details.

## 🤝 Contributing

We welcome contributions! Please follow the standard fork-and-pull-request workflow. Ensure all code follows the established Clean Architecture patterns and passes existing tests.

## 📄 License

This project is licensed under the MIT License.
