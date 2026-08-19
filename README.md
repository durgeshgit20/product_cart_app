# Product Cart App 🛒

A modern, high-performance Flutter e-commerce application built with **Clean Architecture** (Data, Domain, Presentation) and **BLoC (Business Logic Component)** state management. The app consumes REST APIs using **Dio**, manages dependency injection seamlessly with **GetIt** & **Injectable**, and offers a responsive UI with **Google Fonts**.

---

## 🌟 Key Features

- 📱 **Product Catalog Listing**: Browse available products with images, title, category, stock info, and formatted pricing.
- 🔄 **Pull-to-Refresh & Live Synchronization**: Fetch updated product listings and sync price changes across the cart and catalog dynamically.
- 🛒 **Cart Management**:
  - Add / remove products to and from cart.
  - Adjust product quantities (+ / -).
  - Synchronized cart item count badge and real-time total price calculation.
- ⚡ **Clean Architecture & Decoupled Codebase**: Strict separation between Data, Domain, and Presentation layers for testability and maintainability.
- 🎨 **Modern Aesthetics**: Built with Material 3 components and custom typography via `google_fonts`.

---

## 🏗️ Architecture & Design Pattern

The application strictly adheres to **Clean Architecture** principles without unneeded boilerplate:

```
lib/
├── core/                        # Core utilities, network clients, DI & themes
│   ├── network/                 # Dio client & API configurations
│   ├── theme/                   # Material 3 design system & typography
│   └── injection/               # GetIt & Injectable dependency setup
│
└── features/                    # Feature modules
    ├── products/                # Product Listing Feature
    │   ├── data/                # Data sources & repository implementations
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
2. **Domain Layer**: Core Business Logic, Entities, and Repository Interfaces (`i_product_repository.dart`, `i_cart_repository.dart`). Completely framework-agnostic.
3. **Data Layer**: API Remote Data Sources (`Dio`), Data Models, and Repository Implementations (`product_repository_impl.dart`).

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
   git clone https://github.com/djsawant96/product_cart_app.git
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

Run Flutter unit and widget tests with:
```bash
flutter test
```

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
