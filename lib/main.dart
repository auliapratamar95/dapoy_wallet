import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';

const String supabaseUrl = 'https://vwfriffzafrklnwkqfns.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3ZnJpZmZ6YWZya2xud2txZm5zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwODkzMDEsImV4cCI6MjEwODY2NTMwMX0.eL3qPU3s3Oo62mtuA5T7e-ma_PFM9SPNSO59nfEI_3o';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase init warning: $e');
  }

  runApp(
    const ProviderScope(
      child: DapoyWalletApp(),
    ),
  );
}
