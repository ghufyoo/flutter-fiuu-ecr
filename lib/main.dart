import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'features/ecr_communication/presentation/screens/ecr_screen.dart';

void main() {
  // Initialize dependency injection
  ServiceLocator().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter ECR Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => ServiceLocator().createEcrBloc(),
        child: const EcrScreen(),
      ),
    );
  }
}
