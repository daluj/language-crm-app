# Language Teacher CRM Application

## Project Overview

This is a comprehensive Customer Relationship Management (CRM) application designed specifically for language teachers and small language schools. The application helps manage students, schedule classes, track payments, and visualize business performance through an intuitive dashboard.

## Technology Stack

- **Framework**: Flutter (cross-platform)
- **State Management**: Provider
- **Database**: SQLite (via sqflite package)
- **UI Components**: Material Design 3
- **Charts**: fl_chart
- **PDF Generation**: pdf + printing packages
- **Calendar**: table_calendar

## Project Structure

```
language-crm-app/
├── android/            # Android platform-specific code
├── ios/                # iOS platform-specific code
├── lib/                # Main application code
│   ├── models/         # Data models
│   ├── screens/        # UI screens
│   ├── widgets/        # Reusable UI components
│   ├── main.dart       # Application entry point
│   └── theme.dart      # Theme configuration
├── web/                # Web platform-specific code
└── pubspec.yaml        # Dependencies and app metadata
```

## Data Models

### Student Model (`models/student_model.dart`)

Represents a language student with the following properties:
- id (unique identifier)
- name
- email
- phone
- language (the language they're learning)
- level
- notes
- timestamps (created_at, updated_at)

### Class Model (`models/class_model.dart`)

Represents a scheduled or completed class with the following properties:
- id (unique identifier)
- studentId (foreign key to Student)
- title
- description
- dateTime (ISO 8601 format)
- duration (in minutes)
- status (scheduled, completed, cancelled)
- timestamps (created_at, updated_at)

### Payment Model (`models/payment_model.dart`)

Represents a payment made by a student with the following properties:
- id (unique identifier)
- studentId (foreign key to Student)
- amount
- date (YYYY-MM-DD)
- status (paid, pending, cancelled)
- description
- invoiceNumber
- timestamps (created_at, updated_at)

### Database Helper (`models/database_helper.dart`)

Manages SQLite database operations including:
- Database initialization
- Table creation
- CRUD operations for all models

## Screens

### Dashboard Screen (`screens/dashboard_screen.dart`)

Provides an overview of the business with:
- Student count statistics
- Class statistics (scheduled, completed, cancelled)
- Payment statistics and revenue charts
- Upcoming classes list

### Students Screen (`screens/students_screen.dart`)

Manages student information with:
- List of all students with search functionality
- Student details view
- Add/Edit/Delete student operations
- Student history (classes and payments)

### Classes Screen (`screens/classes_screen.dart`)

Manages class scheduling with:
- Calendar view of classes
- Class details view
- Add/Edit/Delete class operations
- Class filtering by student

### Billing Screen (`screens/billing_screen.dart`)

Manages payments with:
- List of all payments with filtering
- Payment details view
- Add/Edit/Delete payment operations
- Invoice generation and printing functionality

## Widgets

### Common Widgets (`widgets/common_widgets.dart`)

Reusable UI components including:
- SectionHeader
- StatCard
- Custom form fields
- Loading indicators
- Error displays

## Theme

The application uses Material Design 3 with a custom color scheme defined in `theme.dart`. The primary colors are:
- Primary: #6F61EF (purple)
- Secondary: #39D2C0 (teal)
- Tertiary: #EE8B60 (orange)

The app uses Google Fonts' Inter font family for consistent typography across platforms.

## Setup Instructions

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio or Xcode (for mobile deployment)
- Chrome (for web deployment)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/language-crm-app.git
   cd language-crm-app
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the application:
   ```
   flutter run
   ```

### Platform-Specific Setup

#### Android

- Minimum SDK version: 21 (Android 5.0)
- Target SDK version: 33 (Android 13)

#### iOS

- Minimum iOS version: 11.0
- Display name: Dreamflow (as configured in Info.plist)

#### Web

- The application is configured for web deployment with appropriate icons and manifest

## Development Guidelines

### State Management

The application uses the Provider pattern for state management. Each model has a corresponding provider class that handles data operations and notifies listeners of changes.

### Database Operations

All database operations are performed asynchronously to avoid blocking the UI thread. The application follows the repository pattern with the following flow:

1. UI interacts with Provider classes
2. Providers use model methods to perform CRUD operations
3. Models use DatabaseHelper to execute SQL operations

### UI/UX Principles

- Material Design 3 components for consistent look and feel
- Responsive layouts that work across different screen sizes
- Animations for smoother transitions between states
- Form validation for data integrity

## Features

- **Student Management**: Add, edit, and delete student records
- **Class Scheduling**: Calendar-based class scheduling and management
- **Payment Tracking**: Record and track student payments
- **Invoicing**: Generate and print professional invoices
- **Dashboard**: Visualize business performance with charts and statistics
- **Search & Filter**: Find information quickly with search and filter capabilities
- **Data Export**: Export data to PDF format

## Dependencies

Key packages used in this project:

- `printing`: ^5.0.0 - For PDF printing functionality
- `pdf`: ^3.0.0 - For PDF generation
- `table_calendar`: ^3.0.0 - For calendar views
- `flutter_slidable`: ^4.0.0 - For swipe actions in lists
- `intl`: 0.20.2 - For internationalization and date formatting
- `sqflite`: ^2.0.0 - For SQLite database operations
- `fl_chart`: 0.68.0 - For charts and graphs
- `google_fonts`: 6.1.0 - For custom typography
- `provider`: 6.1.2 - For state management

## License

[Specify your license here]

---

This README provides comprehensive information about the Language Teacher CRM application, including its structure, models, screens, and setup instructions. This documentation should be sufficient for an AI to understand and recreate the project.