import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'https://togvyunjydjgmaprgxpt.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRvZ3Z5dW5qeWRqZ21hcHJneHB0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4MzM4ODAsImV4cCI6MjA5MzQwOTg4MH0.dTqsunJ1ntODdcOeGOZEPXggnxHyOl8DLuoBghpx6Yw'),
  );

  runApp(const VendasApp());
}
