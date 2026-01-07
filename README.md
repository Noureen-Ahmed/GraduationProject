# Student Dashboard Flutter App

A Flutter implementation of the student dashboard mobile application with comprehensive academic features.

## Features

### 🏠 Dashboard Shell
- **Bottom Navigation**: 5-tab navigation (Home, Tasks, Schedule, Navigate, Profile)
- **GoRouter**: Modern navigation state management
- **Persistent Shell**: State preserved when switching tabs
- **Global App Bar**: Branding and user information
- **Riverpod State Management**: Data-driven UI components

### 📱 Home Screen
- **User Header**: Avatar, name, email from UserRepository
- **Announcement Banner**: Live announcement data with type indicators
- **Quick Actions Grid**: Easy access to main features
- **Progress Cards**: Course and task metrics
- **Professor FAB**: + button for content creation (AppModeController)
- **Pull-to-Refresh**: Data synchronization
- **Loading States**: Shimmer skeletons for better UX

### ✅ Tasks Feature
- **Segmented List**: Pending vs Completed tabs
- **Advanced Filtering**: Status, Priority, Due Date filters
- **Live Search**: Real-time task filtering
- **Task Cards**: Rich display with badges and indicators
- **Interactive Actions**: Checkbox completion, swipe-to-delete
- **Task Details**: Full description, timestamps, history
- **Create/Edit Tasks**: Form validation and repository integration
- **Repository Pattern**: Clean data flow through TaskRepository

### 📅 Schedule/Calendar
- **Calendar Grid**: table_calendar integration
- **View Toggle**: Day/Week/Month views
- **Event Highlighting**: Visual indicators on calendar
- **Upcoming Events**: Next 7 days list
- **Event Cards**: Time, location, instructor info
- **Event Details**: Full descriptions and resources
- **Repository Integration**: ScheduleRepository data flow

### 📚 Courses Module
- **Course List**: Searchable and filterable
- **Enrollment Badges**: Status indicators
- **Course Cards**: Rich information display
- **Course Detail Screen**:
  - Hero gradient header
  - Course information section
  - Tabbed interface: Syllabus | Assignments | Exams
  - Comprehensive content display
- **Repository Pattern**: CourseRepository data management

### 🎨 UI/UX Quality
- **Pixel-Perfect Design**: Matches React color palette and typography
- **Smooth Transitions**: Animated navigation between screens
- **Pull-to-Refresh**: Available on all list screens
- **Loading States**: Spinners and error overlays
- **Professor Mode**: Dynamic UI based on AppModeController
- **No Hardcoded Data**: Everything flows through repositories
- **Responsive Layout**: Adapts to different screen sizes

## Architecture

### 📁 Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── task.dart
│   ├── announcement.dart
│   ├── course.dart
│   ├── schedule_event.dart
│   └── user.dart
├── repositories/             # Data layer
│   ├── task_repository.dart
│   ├── announcement_repository.dart
│   ├── course_repository.dart
│   ├── schedule_repository.dart
│   └── user_repository.dart
├── providers/               # Riverpod state management
│   ├── task_provider.dart
│   ├── announcement_provider.dart
│   ├── course_provider.dart
│   ├── schedule_provider.dart
│   └── app_mode_provider.dart
├── screens/                 # UI screens
│   ├── dashboard_shell.dart
│   ├── home_screen.dart
│   ├── tasks_screen.dart
│   ├── schedule_screen.dart
│   ├── navigate_screen.dart
│   ├── profile_screen.dart
│   └── course_detail_screen.dart
├── widgets/                 # Reusable components
│   ├── task_card.dart
│   ├── announcement_banner.dart
│   ├── quick_action_card.dart
│   ├── progress_card.dart
│   ├── schedule_event_card.dart
│   ├── user_avatar.dart
│   └── loading_shimmer.dart
└── utils/                   # Utility functions
```

### 🏗️ Architecture Patterns
- **Repository Pattern**: Clean separation between data and UI
- **State Management**: Riverpod for reactive state
- **Navigation**: GoRouter for type-safe routing
- **Dependency Injection**: Provider-based DI
- **Model-View-ViewModel (MVVM)**: Clean architecture

### 🔄 Data Flow
1. **Repository Layer**: Mock data with async operations
2. **Provider Layer**: Riverpod providers for state management
3. **UI Layer**: Reactive widgets that listen to providers
4. **Controller Layer**: Business logic and state mutations

## Testing

### 🧪 Widget Tests
- Home screen rendering tests
- Bottom navigation switching
- Task list filtering
- Search functionality
- UI component interactions

### 🔧 State Tests
- AppModeController state management
- TaskRepository operations
- Provider state mutations
- Model serialization/deserialization
- Integration between components

### 🚀 Integration Tests
- Complete app flow testing
- Login → Dashboard → Tab navigation
- Data flow verification
- Professor mode functionality
- Cross-feature interactions

## Dependencies

### Core Dependencies
- `flutter_riverpod`: State management
- `go_router`: Navigation
- `table_calendar`: Calendar widget
- `shimmer`: Loading animations
- `intl`: Date formatting
- `cached_network_image`: Image caching

### Development Dependencies
- `flutter_test`: Testing framework
- `integration_test`: Integration testing
- `flutter_lints`: Code quality

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- IDE with Flutter support

### Installation
1. Clone the repository
2. Navigate to the flutter_project directory
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

### Development
- Run tests: `flutter test`
- Run integration tests: `flutter test integration_test/`
- Build for production: `flutter build apk` or `flutter build ios`
- Seed Professor Account: Run `node backend/seed_professor.js`

### 🔑 Credentials
- **Student**: Register a new account
- **Professor**: 
  - Email: `doctor@university.edu`
  - Password: `password123`

## Key Features Implementation

### 🎯 Professor Mode
- Controlled by `AppModeController`
- Shows/hides UI elements dynamically
- Enables content creation features
- Persists across navigation

### 📊 Real-time Data
- All data flows through repositories
- Reactive UI updates with Riverpod
- Mock data with realistic async delays
- Error handling and loading states

### 🎨 Design System
- Material 3 design principles
- Consistent color scheme
- Typography hierarchy
- Responsive layouts

### 🔍 Search & Filter
- Live search functionality
- Multiple filter criteria
- Combinatorial filtering
- State preservation

## Future Enhancements

- [x] Real backend integration
- [x] Authentication system
- [ ] Push notifications
- [ ] Offline support
- [ ] AR navigation implementation
- [ ] Advanced analytics
- [ ] Social features
- [ ] File attachments
- [ ] Video conferencing integration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.