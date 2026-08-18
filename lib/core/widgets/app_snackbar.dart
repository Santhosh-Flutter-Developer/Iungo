import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';

class AppSnackbar {
  AppSnackbar._();

  static void showError(String message) {
    Get.rawSnackbar(
      messageText: Row(
        children: [
          const Icon(Icons.cancel, color: AppColors.snackbarIcon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.close, color: AppColors.white, size: 18),
        ],
      ),
      backgroundColor: AppColors.snackbarBackground,
      borderRadius: 8,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      isDismissible: true,
    );
  }

  static void showSuccess(String message) {
    Get.rawSnackbar(
      messageText: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.snackbarBackground,
      borderRadius: 8,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      isDismissible: true,
    );
  }
}
