class Constants {
  // Validation
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  // Messages
  static const String networkError = 'Network error. Please try again.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unexpectedError = 'An unexpected error occurred.';
  
  // API timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
}
