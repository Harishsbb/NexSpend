# NexSpend

NexSpend is a comprehensive, cross-platform personal finance and expense tracking application built with Flutter and Firebase. It helps users manage their accounts, track daily transactions, monitor budgets, and gain valuable insights into their spending habits.

## 🌟 Features

*   **Secure Authentication**: User sign-up and login powered by Firebase Auth.
*   **Interactive Dashboard**: A beautiful, unified view of your total balance, recent transactions, and account summaries.
*   **Account Management**: Create and manage multiple accounts (Cash, Bank, Cards) to keep track of money across different sources.
*   **Expense & Income Tracking**: Easily add, categorize, and view transactions.
*   **Budget Management**: Set monthly limits for different categories and get visual progress bars warning you when you are approaching or exceeding limits.
*   **Analytics & Insights**: Dedicated analytics screen with an "Insight Engine" to break down spending patterns over time.
*   **Customizable Profile**: Update your personal details and upload a custom profile picture.
*   **Dark Mode Support**: Adapts automatically to your system's theme for comfortable viewing in low light.

## 🛠️ Tech Stack

*   **Framework**: [Flutter](https://flutter.dev/) (Dart)
*   **Backend & Database**: Firebase (Auth, Cloud Firestore, Cloud Storage)
*   **State Management**: Riverpod (`flutter_riverpod`)
*   **Local Storage**: Hive (`hive`, `hive_flutter`)
*   **Data Visualization**: FL Chart (`fl_chart`)
*   **Other Integrations**:
    *   `image_picker` / `file_picker` for profile photos
    *   `intl` for currency and date formatting
    *   `google_fonts` & `font_awesome_flutter` for beautiful typography and iconography

## 🚀 Getting Started

To run this project locally, follow these steps:

### Prerequisites

1.  [Install Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.11.1 or higher)
2.  Set up an IDE like VS Code or Android Studio.
3.  Have a connected device, emulator, or use Chrome for web debugging.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Harishsbb/NexSpend.git
    cd NexSpend
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```
    *(For web development, you can use `flutter run -d chrome`)*

### Firebase Configuration
If you are setting this up as your own instance, you will need to connect it to your own Firebase project.
1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable Authentication (Email/Password), Firestore Database, and Firebase Storage.
3. Use [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) to configure your project and generate the `firebase_options.dart` file.

## 📱 Screenshots

*(Consider adding screenshots of your Dashboard, Analytics, and Add Expense screens here later to make your repository look even better!)*

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/Harishsbb/NexSpend/issues).

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
