import 'package:flutter/material.dart';

// Kullanıcı ekranları
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/user/home_screen.dart';
import '../screens/user/exercise_screen.dart';
import '../screens/user/program_list_screen.dart';
import '../screens/user/bottom_nav_screen.dart';
import '../screens/user/onboarding_screen.dart';
import '../screens/user/settings_screen.dart';
import '../screens/user/search_screen.dart';
import '../screens/user/complete_profile_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/user/contact_us_screen.dart'; // <-- BU ÖNEMLİ

// Admin ekranları
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/add_food_screen.dart';
import '../screens/admin/add_exercise_screen.dart';
import '../screens/admin/add_program_screen.dart';
import '../screens/admin/edit_program_screen.dart';
import '../screens/admin/add_exercise_to_program_screen.dart';
import '../screens/admin/admin_messages_screen.dart';
import '../screens/admin/users_screen.dart';

class AppRoutes {
  // Kullanıcı yönlendirmeleri
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const exercise = '/exercise';
  static const programs = '/programs';
  static const onboarding = '/onboarding';
  static const settings = '/settings';
  static const search = '/search';
  static const forgotPassword = '/forgot_password';
  static const completeProfile = '/complete_profile';
  static const contactUs = '/contact_us';

  // Admin yönlendirmeleri
  static const adminDashboard = '/admin_dashboard';
  static const addFood = '/add_food';
  static const addExercise = '/add_exercise';
  static const addProgram = '/add_program';
  static const editProgram = '/edit_program';
  static const addExerciseToProgram = '/add_exercise_to_program';
  static const adminMessages = '/admin_messages';
  static const users = '/users';
  static Map<String, WidgetBuilder> routes = {
    // Kullanıcı sayfaları
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const BottomNavScreen(),
    programs: (context) => const ProgramListScreen(),
    exercise: (context) => const ExerciseScreen(),
    onboarding: (context) => const OnboardingScreen(),
    settings: (context) => const SettingsScreen(),
    search: (context) => const SearchScreen(),
    forgotPassword: (context) => ForgotPasswordScreen(),
    completeProfile: (context) => const CompleteProfileScreen(),
    contactUs: (context) => const ContactUsScreen(),
    adminMessages: (context) => const AdminMessagesScreen(),
    users: (context) => const UsersScreen(),
    // Admin sayfaları
    adminDashboard: (context) => const AdminDashboard(),
    addFood: (context) => AddFoodScreen(),
    addExercise: (context) => AddExerciseScreen(),
    addProgram: (context) => const AddProgramScreen(),
    editProgram: (context) => const EditProgramScreen(programId: ''),
    addExerciseToProgram: (context) {
      final programId = ModalRoute.of(context)!.settings.arguments as String;
      return AddExerciseToProgramScreen(programId: programId);
    },
  };
}
