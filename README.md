# Flutter ECR Terminal Communication

This Flutter application is specifically designed for **Android developers** who need to connect their **ECR (Electronic Cash Register) terminals** to Flutter apps via **USB serial communication**.

⚠️ **Important**: This solution is **Android-only** and requires direct USB connection to ECR terminals.

## 🎯 Who This Is For

This repository is intended for developers who:

- Need to integrate ECR/payment terminals with Flutter Android apps
- Want to send payment requests and receive responses via USB serial
- Are working with terminals that support ECR protocol communication
- Require real-time transaction processing capabilities

## 🔧 Prerequisites Setup

### Step 1: Get Your ECR Terminal's USB Identifiers

Before you can connect to your ECR terminal, you need to identify its **Vendor ID (VID)** and **Product ID (PID)**.

#### On macOS:

```bash
system_profiler SPUSBDataType
```

#### On Windows:

```powershell
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB' }
```

Look for your ECR terminal in the output and note down the VID and PID values.

### Step 2: Configure Device Filter

Create or update `android/app/src/main/res/xml/device_filter.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <usb-device vendor-id="YOUR_VENDOR_ID" product-id="YOUR_PRODUCT_ID" />
    <!-- Example for common ECR terminals: -->
    <!-- <usb-device vendor-id="1659" product-id="8963" /> -->
</resources>
```

Replace `YOUR_VENDOR_ID` and `YOUR_PRODUCT_ID` with the values you found in Step 1.

### Step 3: Configure Android Manifest

Update your `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- USB permissions -->
    <uses-feature android:name="android.hardware.usb.host" />
    <uses-permission android:name="android.permission.USB_PERMISSION" />

    <application
        android:label="flutter_ecr_test"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme">

            <!-- USB device intent filter -->
            <intent-filter>
                <action android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED" />
            </intent-filter>

            <meta-data
                android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED"
                android:resource="@xml/device_filter" />

            <!-- Standard app launch intent -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### Step 4: Install USB Serial Plugin

Add the `usb_serial` plugin to your `pubspec.yaml`:

```yaml
dependencies:
  usb_serial: ^0.5.2
```

Then run:

```bash
flutter pub get
```

## 🔄 Communication Logic Overview

### ECR Protocol Flow

The ECR communication follows this pattern:

1. **Device Detection**: App scans for available USB devices
2. **Connection**: Establishes serial connection with ECR terminal
3. **Message Construction**: Builds ECR protocol messages
4. **Transaction Request**: Sends payment/transaction requests
5. **Response Processing**: Receives and parses terminal responses
6. **Logging**: Real-time communication monitoring

### Message Structure

ECR messages follow this format:

```
STX + LENGTH + TRANSPORT_HEADER + PRESENTATION_HEADER + FIELD_DATA + ETX + LRC
```

- **STX**: Start of Text (0x02)
- **LENGTH**: Message length in BCD format
- **TRANSPORT_HEADER**: Protocol routing information
- **PRESENTATION_HEADER**: Transaction type and response codes
- **FIELD_DATA**: Transaction details (amount, transaction ID, etc.)
- **ETX**: End of Text (0x03)
- **LRC**: Longitudinal Redundancy Check for error detection

### Key Communication Components

#### 1. **Device Management**

- USB device enumeration
- Serial port configuration (115200 baud, 8N1)
- Connection state management
- Error handling and recovery

#### 2. **Message Building**

- Purchase transaction messages (code '20')
- Field encoding with proper BCD conversion
- LRC checksum calculation
- Transport and presentation header construction

#### 3. **Response Processing**

- Hex data parsing
- Field extraction and validation
- Transaction result code interpretation
- Real-time response logging

#### 4. **Transaction Types Supported**

- **Purchase Transactions**: Standard payment processing
- **Custom Commands**: Raw hex data transmission
- **Status Queries**: Terminal health checks
- **Configuration**: Terminal setup commands

### Usage Example

```dart
// 1. Load available devices
context.read<EcrBloc>().add(LoadAvailableDevices());

// 2. Connect to ECR terminal
context.read<EcrBloc>().add(ConnectToDeviceEvent(selectedDevice));

// 3. Send payment request
final message = EcrMessage(
  transactionId: 'TXN001',
  amount: '1000', // $10.00 in cents
  merchantIndex: '01',
);
context.read<EcrBloc>().add(SendEcrMessageEvent(message));

// 4. Handle response in BlocListener
BlocListener<EcrBloc, EcrState>(
  listener: (context, state) {
    if (state is EcrDeviceConnected) {
      // Process transaction response from logs
      final logs = state.logs;
      // Parse response data...
    }
  },
  child: YourWidget(),
)
```

## 📱 Testing Your Setup

1. **Connect ECR Terminal**: Plug your ECR terminal into Android device via USB
2. **Grant Permissions**: Android will prompt for USB device permissions
3. **Run App**: Launch the Flutter app
4. **Verify Detection**: Check if your terminal appears in the device list
5. **Test Connection**: Try connecting to the terminal
6. **Send Test Transaction**: Use the payment request form to send a small amount

## 🚨 Common Issues

### Device Not Detected

- Verify VID/PID in device_filter.xml match your terminal
- Check USB cable and connection
- Ensure Android USB debugging is enabled
- Grant USB permissions when prompted

### Connection Failed

- Confirm ECR terminal is in the correct mode
- Check serial port parameters (baud rate, data bits)
- Verify terminal is not connected to another app
- Try different USB cables or ports

### Transaction Errors

- Validate ECR message format
- Check transaction amount formatting (cents)
- Ensure merchant configuration is correct
- Review terminal-specific protocol requirements

## 📋 Requirements

- **Flutter**: 3.0 or higher
- **Android**: API level 21+ (Android 5.0)
- **ECR Terminal**: USB serial communication support
- **USB OTG**: Android device with USB host support
- **Permissions**: USB device access

## 📚 Additional Resources

- [ECR Protocol Documentation](ARCHITECTURE.md) - Detailed architecture overview
- [Flutter USB Serial Plugin](https://pub.dev/packages/usb_serial)
- [Android USB Host Documentation](https://developer.android.com/guide/topics/connectivity/usb/host)

---

**Note**: This is a specialized tool for ECR integration. Ensure you understand your terminal's specific protocol requirements and test thoroughly before production use.
