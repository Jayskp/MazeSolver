import 'package:flutter/material.dart';
import 'package:maze_solver/maze_solver_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Home Page'),
        ),
        body: MazeSolverScreen(),
        ),
    );
  }
}

void main() {
  runApp(const MyApp());
}
