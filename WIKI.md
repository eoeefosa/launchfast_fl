# LaunchFast FL - Project Wiki

Welcome to the **LaunchFast FL** documentation. This project is a robust, multi-role delivery platform built with Flutter, designed to support Customers, Store Owners, and Riders in a unified ecosystem.

## 🚀 Project Overview

LaunchFast FL is a feature-rich delivery application that leverages real-time communication and a modular architecture to provide a seamless experience across different user roles.

- **Customer:** Browse stores, add items to cart, place orders, and track them in real-time.
- **Store Owner:** Manage menu items, accept/reject orders, and update order status.
- **Rider:** View available delivery tasks, accept orders, and provide real-time location updates.

---

## 🏗 Architecture & Design Patterns

The project follows a clean, modular architecture combining industry-standard design patterns:

- **State Management:** [Provider](https://pub.dev/packages/provider) is used for reactive state management across the app.
- **Dependency Injection:** [GetIt](https://pub.dev/packages/get_it) acts as a service locator for managing singletons (services and repositories).
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router) handles complex routing, including shell-based tab navigation and deep linking.
- **Networking:** [Dio](https://pub.dev/packages/dio) is utilized for REST API communication.
- **Real-time Updates:** [Ably](https://pub.dev/packages/ably_flutter) powers the real-time event system for order tracking and role-specific notifications.

---

## 📦 Core Modules

### 1. State Management (Providers)
Located in `lib/providers/`, these handle the business logic and UI state:
- **AuthProvider:** Manages user sessions, role-based access, and profile updates.
- **CartProvider:** Handles local cart state, tax calculations, and item management.
- **OrderProvider:** Manages the lifecycle of orders and real-time status updates.
- **StoreProvider:** Fetches and filters store data and menu items.
- **NotificationProvider:** Manages in-app notifications and alerts.

### 2. Data Models
Located in `lib/models/`, using JSON serialization for data consistency:
- `User`, `Store`, `Order`, `MenuItem`, `CartItem`, `Rider`, `NotificationItem`.

### 3. Services & Repositories
- **AblyService:** The backbone for real-time features. It handles channel subscriptions for user-specific and order-specific updates.
- **AuthRepository:** Handles API calls for login, registration, and logout.
- **MenuRepository:** Manages data fetching for stores and their menus.

---

## 🛠 Developer Tools & Analysis

The project includes built-in tools for architectural analysis and visualization:

- **Graphify:** An automated tool that generates a knowledge graph of the codebase. It identifies "communities" (logical clusters) and "God Nodes" (core pillars like Material, GoRouter, and Provider).
- **Project Visualization:** Detailed reports can be found in `graphify-out/GRAPH_REPORT.md`, providing insights into:
    - **Core Abstractions:** The most connected nodes in the system.
    - **Logical Communities:** Clusters like "Checkout Process", "Order Tracking", and "Notifications Management".
    - **Navigation Map:** A high-level view of how screens and components interconnect.

---

## ✨ Key Features

### 📡 Real-time Synchronization
Using Ably, the app provides instant updates for:
- Order status changes (Pending -> Preparing -> Out for Delivery -> Delivered).
- Dynamic role switching (e.g., a user becoming a rider).
- Real-time notifications across devices.

### 🔐 Secure Authentication
- Supports Email/Password login and **Google Sign-In**.
- Token persistence using `flutter_secure_storage`.
- Role-based redirection logic within the router.

### 🎨 Responsive & Animated UI
- **Flutter ScreenUtil:** Ensures the UI scales correctly across different screen sizes.
- **Flutter Animate:** Provides smooth transitions and interactive elements.
- **Theme Support:** Managed via `ThemeProvider` for light/dark mode and brand colors.

---

## 📂 Directory Structure

```text
lib/
├── constants/     # Global constants, colors, and static data
├── models/        # Data classes and JSON serialization
├── providers/     # Business logic and state management
├── repositories/  # Data abstraction layer for API calls
├── screens/       # Full-page UI components
├── services/      # Low-level service integrations (Ably, Dio)
├── utils/         # Helper functions and formatters
├── widgets/       # Reusable UI components
├── locator.dart   # Dependency injection setup
├── main.dart      # App entry point and initialization
└── router.dart    # Navigation configuration
```

---

## 🛠 Tech Stack

| Category | Package |
| :--- | :--- |
| **State Management** | `provider` |
| **Navigation** | `go_router` |
| **Networking** | `dio` |
| **Real-time** | `ably_flutter` |
| **DI** | `get_it` |
| **Local Storage** | `shared_preferences`, `flutter_secure_storage` |
| **UI/UX** | `flutter_screenutil`, `flutter_animate`, `google_fonts` |

---

## 🛠 Getting Started

1. **Prerequisites:** Ensure you have the Flutter SDK installed (`^3.11.5`).
2. **Setup:**
   ```bash
   flutter pub get
   ```
3. **Environment:** Configure your Ably and API keys (usually via a `.env` file or constants).
4. **Run:**
   ```bash
   flutter run
   ```

---

*Documentation generated by Gemini CLI.*
