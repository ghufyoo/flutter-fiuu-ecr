# Flutter ECR Communication App - Clean Architecture

This Flutter application provides ECR (Electronic Cash Register) communication functionality using clean architecture principles and BLoC pattern for state management.

## Architecture Overview

The application follows **Clean Architecture** principles with clear separation of concerns across different layers:

### 📁 Project Structure

```
lib/
├── main.dart                    # Application entry point
├── core/                       # Core shared functionality
│   ├── di/                     # Dependency injection
│   │   └── service_locator.dart
│   ├── error/                  # Error handling
│   │   └── failures.dart
│   └── usecases/               # Base use case interface
│       └── usecase.dart
└── features/                   # Feature modules
    └── ecr_communication/      # ECR communication feature
        ├── data/               # Data layer
        │   ├── datasources/    # External data sources
        │   │   └── serial_data_source.dart
        │   ├── models/         # Data models
        │   │   └── usb_device_model.dart
        │   ├── repositories/   # Repository implementations
        │   │   └── ecr_repository_impl.dart
        │   └── services/       # Data services
        │       └── ecr_message_builder.dart
        ├── domain/             # Domain layer
        │   ├── entities/       # Business entities
        │   │   ├── communication_log.dart
        │   │   ├── ecr_message.dart
        │   │   └── usb_device_entity.dart
        │   ├── repositories/   # Repository interfaces
        │   │   └── ecr_repository.dart
        │   └── usecases/       # Business use cases
        │       ├── connect_to_device.dart
        │       ├── disconnect_from_device.dart
        │       ├── get_available_devices.dart
        │       └── send_ecr_message.dart
        └── presentation/       # Presentation layer
            ├── bloc/           # BLoC state management
            │   ├── ecr_bloc.dart
            │   ├── ecr_event.dart
            │   └── ecr_state.dart
            ├── screens/        # Screen widgets
            │   └── ecr_screen.dart
            ├── widgets/        # Reusable widgets
            │   ├── communication_log_widget.dart
            │   ├── device_list.dart
            │   ├── hex_data_input.dart
            │   └── payment_request_form.dart
            └── services/       # Presentation services
                └── terminal_response_parser.dart
```

## Clean Architecture Layers

### 🏛️ **Domain Layer** (Business Logic)

- **Entities**: Core business models (`UsbDeviceEntity`, `EcrMessage`, `CommunicationLog`)
- **Use Cases**: Business operations (`ConnectToDevice`, `SendEcrMessage`, etc.)
- **Repository Interfaces**: Contracts for data access
- **No dependencies on external frameworks**

### 📊 **Data Layer** (Data Access)

- **Data Sources**: External data access (`SerialDataSource`)
- **Models**: Data transfer objects extending domain entities
- **Repository Implementations**: Concrete implementations of domain interfaces
- **Services**: Data processing utilities (`EcrMessageBuilder`)

### 🎨 **Presentation Layer** (UI & State Management)

- **BLoC**: State management using flutter_bloc
- **Screens**: Page-level widgets
- **Widgets**: Reusable UI components
- **Services**: UI-specific utilities

### 🛠️ **Core Layer** (Shared Infrastructure)

- **Dependency Injection**: Service locator pattern
- **Error Handling**: Centralized failure classes
- **Use Case Base**: Common interface for all use cases

## Key Benefits

### ✅ **Improved Readability**

- Clear separation of concerns
- Well-organized folder structure
- Single responsibility principle
- Descriptive naming conventions

### ✅ **Better Testability**

- Each layer can be tested independently
- Dependency injection enables easy mocking
- Business logic separated from UI concerns
- Use cases represent testable business operations

### ✅ **Enhanced Maintainability**

- Changes in one layer don't affect others
- Easy to add new features
- Framework-independent business logic
- Consistent error handling

### ✅ **Professional Architecture**

- Industry-standard patterns
- Scalable structure
- Team collaboration friendly
- Future-proof design

## BLoC Pattern Implementation

### Events (User Interactions)

- `LoadAvailableDevices`
- `ConnectToDeviceEvent`
- `SendEcrMessageEvent`
- `DisconnectFromDeviceEvent`
- `ClearLogsEvent`

### States (UI States)

- `EcrInitial`
- `EcrLoading`
- `EcrDevicesLoaded`
- `EcrDeviceConnected`
- `EcrError`

### BLoC (Business Logic Component)

- Handles events and emits states
- Manages USB device connections
- Processes ECR communication
- Maintains communication logs

## Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.6 # State management
  equatable: ^2.0.5 # Value equality
  dartz: ^0.10.1 # Functional programming (Either)
  usb_serial: ^0.5.2 # USB serial communication
  convert: ^3.1.2 # Data conversion utilities
```

## Usage

### Device Connection

```dart
// Load available devices
context.read<EcrBloc>().add(LoadAvailableDevices());

// Connect to a device
context.read<EcrBloc>().add(ConnectToDeviceEvent(device));
```

### Sending ECR Messages

```dart
// Send payment request
final message = EcrMessage(
  transactionId: 'TXN123',
  amount: '1000',
  merchantIndex: '01',
);
context.read<EcrBloc>().add(SendEcrMessageEvent(message));
```

### State Listening

```dart
BlocListener<EcrBloc, EcrState>(
  listener: (context, state) {
    if (state is EcrError) {
      // Handle error
    } else if (state is EcrDeviceConnected) {
      // Handle successful connection
    }
  },
  child: YourWidget(),
)
```

## Error Handling

The application uses functional error handling with `Either<Failure, Success>`:

- `DeviceFailure`: Device-related errors
- `ConnectionFailure`: Connection issues
- `DataTransmissionFailure`: Communication errors
- `ParsingFailure`: Data parsing errors

## Testing Strategy

With this architecture, you can easily test:

1. **Unit Tests**: Use cases, entities, and services
2. **Integration Tests**: Repository implementations
3. **Widget Tests**: Individual UI components
4. **BLoC Tests**: State management logic

## Migration from Previous Code

The previous Riverpod-based monolithic code has been refactored to:

1. **Separate concerns** into distinct layers
2. **Use BLoC** instead of Riverpod for better structure
3. **Implement use cases** for business operations
4. **Add proper error handling** with typed failures
5. **Create reusable widgets** with single responsibilities
6. **Enable dependency injection** for better testability

This new architecture provides a solid foundation for future development and maintenance.
