**🔎OVERVIEW**

Hangman - Friend Edition is a simple, interactive word-guessing game built using Flutter Web and is developed in Android Studio.
In contrast to the standard stick-figure hangman, this version adds a fun and customized twist by using staged photographs of a friend that appear as the player makes wrong answers.

**🔀Installation Process:**

1.) Install Flutter:

https://flutter.dev/docs/get-started/install

2.) Clone the repository:

https://github.com/macoconut/AppDev-Project---Hangman-Game

3.) Install Dependencies: 

command: flutter pub get

4.) Use Android Studio:
- Open Android Studio
- Click Open an Existing Project 
- Select the project folder 
- Ensure Flutter plugin + Dart plugin are enabled 
- Run using the Windows (desktop)

**🗂️Project Structure:**

AppDev-Project---Hangman-Game/

│

├── android/           # Android platform files (auto-generated)

├── assets/            # Friend stage images (friend_stage_0.png → friend_stage_5.png)

├── build/             # Build outputs (auto-generated)

├── ios/               # iOS platform files

├── lib/

│   ├── main.dart      # Main UI + game logic

│   └── data/

│       └── words.dart # Word list

│

├── linux/             # Linux platform files

├── macos/             # macOS platform files

├── web/               # Flutter web runner + index.html

├── windows/           # Windows platform files

│

├── test/              # Test folder (default)

├── pubspec.yaml       # Main config (dependencies + assets)

├── pubspec.lock       # Dependency lockfile

├── README.md          # Project documentation
└── .gitignore         # Git ignored files

**🛠️ Tools Used:**
- Flutter Web
- Dart
- Android Studio (IDE for development)
- Custom Assets (for friend stage images)

**💡Features:**
- Usual Hangman Gameplay: Guess the word by typing the letters using the keyboard
- Custom Friend Images: A unique image appears with every wrong attempt
- Hints: When attempts are low, a hint is displayed automatically
- Animations: Includes intro animations, transitions, and shake effects.
- Runs on Flutter Web: Both desktop and mobile browsers are compatible.
- Responsive UI: Smoothly adapts to various screen sizes.
