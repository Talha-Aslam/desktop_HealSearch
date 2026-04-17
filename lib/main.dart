import 'package:desktop_search_a_holic/chatBot.dart';
import 'package:desktop_search_a_holic/imports.dart';
import 'package:desktop_search_a_holic/addProduct.dart';
import 'package:desktop_search_a_holic/editProduct.dart';
import 'package:desktop_search_a_holic/forgetPassword.dart';
import 'package:desktop_search_a_holic/invoice.dart';
import 'package:desktop_search_a_holic/newOrder.dart';
import 'package:desktop_search_a_holic/pos_enhanced.dart' as enhanced;
import 'package:desktop_search_a_holic/product.dart';
import 'package:desktop_search_a_holic/profile.dart';
import 'package:desktop_search_a_holic/reports.dart';
import 'package:desktop_search_a_holic/sales.dart';
import 'package:desktop_search_a_holic/settings_page.dart';
import 'package:desktop_search_a_holic/backup_history_page.dart';
import 'package:desktop_search_a_holic/privacy_policy_page.dart';
import 'package:desktop_search_a_holic/terms_of_service_page.dart';
import 'package:desktop_search_a_holic/splash.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/uploadData.dart';
import 'package:desktop_search_a_holic/stock_alert_service.dart';
import 'package:desktop_search_a_holic/stock_alerts_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  // } catch (e) {
  //   print('Failed to initialize Firebase: $e');
  // }

  await createFilesAndFolders();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<StockAlertService>(
          create: (_) => StockAlertService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'HealSearch',
      theme: themeProvider.themeData,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      builder: (context, child) {
        // Wrap the entire app in error handling and proper focus scope
        return Builder(
          builder: (context) {
            try {
              return FocusScope(
                child: child ?? const SizedBox.shrink(),
              );
            } catch (e) {
              print('Error in app builder: $e');
              return MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('App Error: ${e.toString()}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Restart the app
                            Navigator.pushReplacementNamed(context, '/');
                          },
                          child: const Text('Restart'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
      routes: {
        '/': (context) => const SplashScreen(),
        '/dashboard': (context) => const Dashboard(),
        '/profile': (context) => const Profile(),
        '/products': (context) => const Product(),
        '/addProduct': (context) => const AddProduct(),
        '/editProduct': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final productId = args?['productId'] ?? '1'; // Default fallback
          return EditProduct(productID: productId);
        },
        '/invoices': (context) => const Invoice(),
        '/reports': (context) => const Reports(),
        '/chatBot': (context) => ChatBotPage(),
        '/login': (context) => const Login(),
        '/newOrder': (context) => const NewOrder(),
        '/registration': (context) => const Registration(),
        '/sales': (context) => const Sales(),
        '/uploadData': (context) => const UploadData(),
        '/settings': (context) => const SettingsPage(),
        '/backup-history': (context) => const BackupHistoryPage(),
        '/privacy-policy': (context) => const PrivacyPolicyPage(),
        '/terms-of-service': (context) => const TermsOfServicePage(),
        '/pos': (context) => const enhanced.POS(),
        '/stock-alerts': (context) => const StockAlertsPage(),
        '/forgetPassword': (context) => const ForgetPassword(),
      },
    );
  }
}

Future<void> createFilesAndFolders() async {
  try {
    // Check if we're running on web platform
    if (kIsWeb) {
      print('Running on web platform - file operations are limited');
      return;
    }

    // Creating A Folder in the Document Directory
    Directory directory = await getApplicationDocumentsDirectory();
    print(directory.path);
    String path = directory.path;
    Directory folder = Directory('$path/SeachAHolic');

    // IF There is No Folder in the Document Directory
    if (!folder.existsSync()) {
      folder.create();
      print('Folder created at ${folder.path}');
    } else {
      print('Folder already exists at ${folder.path}');
    }

    // List of files to create
    List<String> filesToCreate = ['products.csv', 'user.json', 'logs.txt'];

    for (String fileName in filesToCreate) {
      File file = File('${folder.path}/$fileName');
      if (!file.existsSync()) {
        await file.create();
        print("$fileName File Created");
      }
    }
  } catch (e) {
    print('Error creating files and folders: $e');
    // Continue app execution even if file creation fails
  }
}
