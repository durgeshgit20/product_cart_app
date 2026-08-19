# Product Cart App 🛒

A modern, high-performance Flutter e-commerce application built with **Clean Architecture** (Data, Domain, Presentation) and **BLoC (Business Logic Component)** state management. The app supports both **Live REST API** integration and **Mock Data Sources**, managed seamlessly via **Injectable** and **GetIt**.

---

## 🌟 Key Features

- 📱 **Product Catalog Listing**: Browse available products with network images, titles, descriptions, stock status, and formatted pricing.
- 🔄 **Pull-to-Refresh & Live Synchronization**: Fetch updated product listings and sync price changes across the cart and catalog dynamically upon pull-to-refresh.
- 🛒 **Cart Management**:
  - Add / remove products to and from cart.
  - Adjust product quantities (+ / -).
  - Synchronized cart item count badge and real-time total price calculation.
- 🧪 **Dual Environment Setup (Mock & Live API)**: Easily switch between a live backend endpoint and an offline mock data source with pre-configured test scenarios.
- ⚡ **Clean Architecture & Decoupled Codebase**: Strict separation between Data, Domain, and Presentation layers for high testability and maintainability.
- 🎨 **Modern Aesthetics**: Built with Material 3 components and custom typography via `google_fonts`.

---

## 🌐 API Data Sources & Testing Environments

The application uses **Injectable** environment annotations (`@Environment`) to decouple the network layer, allowing testers to run the app against a **Live REST API** or an offline **Mock API**.

| Environment Key | Class | Endpoint / Source | Description |
| :--- | :--- | :--- | :--- |
| `Environment.dev` / `Environment.prod` | `ProductRemoteDataSourceImpl` | `https://d998-203-192-225-119.ngrok-free.app/products` | Connects to the live backend server via `Dio` client. |
| `'mock'` | `MockProductRemoteDataSourceImpl` | Local Memory / Simulated Delay | Offline mock data source with built-in scenarios for testing edge cases. |

### 🧪 Pre-configured Mock Test Scenarios

When running under the `'mock'` environment, the data source supports scenario flags to test various UI & BLoC behaviors:

- **`normal` (Default)**: Returns a standard set of products (Headphones, Smartwatch, Keyboard, Speaker).
- **`updated`**: Simulates a backend price change (e.g. Wireless Headphones drop from **$199.99** to **$179.99**). Ideal for testing **Pull-to-Refresh Cart Price Synchronization**.
- **`error`**: Simulates a network failure (`Mock API Error`) to test the **Error View** and **Retry button**.
- **`empty`**: Returns an empty product array to test the **Empty State View**.

### 🛠️ How Testers Can Switch Environments

Open [`lib/main.dart`](file:///Users/durgeshsawant/.gemini/antigravity-ide/scratch/product_cart_app/lib/main.dart) and update `configureDependencies()`:

```dart
// For Live API (default dev endpoint):
configureDependencies(environment: Environment.dev);

// For Offline Mock API testing:
configureDependencies(environment: 'mock');
```

---

## 🏗️ Architecture & Design Pattern

The application strictly adheres to **Clean Architecture** principles:

```
lib/
├── core/                        # Core utilities, network clients, DI & themes
│   ├── network/                 # Dio client & API configurations
│   ├── theme/                   # Material 3 design system & typography
│   └── injection/               # GetIt & Injectable dependency setup
│
└── features/                    # Feature modules
    ├── products/                # Product Listing Feature
    │   ├── data/                # Data sources (Mock & Live) & repository implementations
    │   ├── domain/              # Entities & Repository interfaces
    │   └── presentation/        # BLoC, screens & widget components
    │
    └── cart/                    # Cart Feature
        ├── data/                # Data sources & repository implementations
        ├── domain/              # Entities & Repository interfaces
        └── presentation/        # BLoC, screens & cart bottom sheet/tiles
```

### Architectural Layers

1. **Presentation Layer**: Flutter UI Widgets + **BLoC / Cubit** for predictable unidirectional data flow.
2. **Domain Layer**: Core Business Logic, Entities, and Repository Interfaces (`i_product_repository.dart`). Completely framework-agnostic.
3. **Data Layer**: Remote Data Sources (`MockProductRemoteDataSourceImpl` & `ProductRemoteDataSourceImpl`), Data Models (`ProductDto`), and Repository Implementations (`ProductRepositoryImpl`).

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK `^3.11.1`)
- **State Management**: [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) (`^9.1.1`)
- **Network Client**: [`dio`](https://pub.dev/packages/dio) (`^5.11.0`)
- **Dependency Injection**: [`get_it`](https://pub.dev/packages/get_it) (`^9.2.1`) & [`injectable`](https://pub.dev/packages/injectable) (`^3.0.0`)
- **Value Equality**: [`equatable`](https://pub.dev/packages/equatable) (`^2.1.0`)
- **Typography**: [`google_fonts`](https://pub.dev/packages/google_fonts) (`^8.2.1`)
- **Code Generation**: [`build_runner`](https://pub.dev/packages/build_runner) & [`injectable_generator`](https://pub.dev/packages/injectable_generator)

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version `3.29.0` or later)
- Dart SDK
- Android Studio / Xcode / VS Code with Flutter extension

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/durgeshgit20/product_cart_app.git
   cd product_cart_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Dependency Injection code** (Injectable):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing

Run Flutter unit and widget tests:
```bash
flutter test
```

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
