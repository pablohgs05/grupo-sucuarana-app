import 'package:flutter/material.dart';

void main() {
  runApp(const GrupoSucuaranaApp());
}

class GrupoSucuaranaApp extends StatelessWidget {
  const GrupoSucuaranaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grupo Suçuarana',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grupo Suçuarana')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Base do aplicativo pronta.\n'
            'Os relatórios serão preenchidos offline e sincronizados depois.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
