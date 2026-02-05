# Tabby 🐱

**Tabby** is a native macOS menu bar application designed to help you manage your browser tabs with context. It allows you to add notes to your open tabs and set reminders that sync directly with your Apple Calendar, combating "tab amnesia" and keeping your workflow organized.


## ✨ Features

- **Multi-Browser Support**: Automatically fetches open tabs from **Safari**, **Google Chrome**, and **Arc**.
- **Contextual Notes**: Add quick notes to any tab to remember *why* you kept it open.
- **Smart Reminders**: Set reminders for specific tabs.
  - **Calendar Integration**: Reminders are synced to your **Apple Calendar** as events with alarms.
  - **Local Notifications**: Receive native macOS notifications when it's time to check a tab.
- **Glassmorphism UI**: A beautiful, translucent interface that feels at home on macOS.
  - **Collapsible UI**: Clean interface with expandable inputs for notes and dates.
  - **Dark Mode Support**: Fully compatible with macOS appearance settings.
- **Privacy First**: All data is stored locally on your machine. No external servers involved.
- **Smart Launch**: Only scans browsers that are currently running to avoid accidental launches.

## 🚀 Installation & Usage

### Prerequisites
- macOS 13.0 (Ventura) or later.
- Xcode 14+ (if building from source).

### Running the App

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/idevanshrai/tabby-MacOS.git
    cd tabby
    ```

2.  **Build and Run**:
    You can run the app directly using Swift (though notifications work best in a bundled app):
    ```bash
    swift run
    ```
    
    **Recommended**: For full functionality (Notifications & Calendar permissions), build the `.app` bundle:
    ```bash
    swift build -c release
    cp -r .build/release/Tabby Tabby.app
    open Tabby.app
    ```

3.  **Permissions**:
    - **Automation**: Upon first launch, grant permission for Tabby to control Safari/Chrome/Arc (to read tabs).
    - **Notifications**: Allow notifications to receive alerts.
    - **Calendar**: Allow access to your Calendar to save reminders.

## 🛠 Tech Stack

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Browser Automation**: AppleScript (via `NSAppleScript`)
- **System Integration**:
  - `EventKit` (Calendar & Reminders)
  - `UserNotifications` (Local Alerts)
  - `AppKit` (Menu Bar Extra, Window Management)

## 📂 Project Structure

- `TabbyApp.swift`: Main entry point, sets up the Menu Bar Extra.
- `ContentView.swift`: Main UI implementation (Glassmorphism design).
- `TabManager.swift`: Core logic controller. Handles data persistence, EventKit sync, and state management.
- `BrowserService.swift`: Handles AppleScript execution to fetch tabs from various browsers.
- `TabItem.swift`: Data model for a tab (Title, URL, Note, Reminder).

## 📝 Configuration

You can customize which browsers Tabby scans by clicking the **Gear Icon** within the app:
- Toggle support for **Google Chrome**, **Safari**, or **Arc**.

## 👨‍💻 Author

**Devansh Rai**  
*Software Developer & Open Source Enthusiast*

---

Built with ❤️ for macOS.
