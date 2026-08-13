import 'package:flutter/material.dart';

/// One row inside the "Create Service Request" bottom sheet.
enum ServiceRequestOption { serviceRequest, 
// cateringRequest, laundryRequest 
}

extension ServiceRequestOptionX on ServiceRequestOption {
  IconData get icon {
    switch (this) {
      case ServiceRequestOption.serviceRequest:
        return Icons.description_outlined;
      // case ServiceRequestOption.cateringRequest:
      //   return Icons.restaurant_outlined;
      // case ServiceRequestOption.laundryRequest:
      //   return Icons.local_laundry_service_outlined;
    }
  }

  String get labelKey {
    switch (this) {
      case ServiceRequestOption.serviceRequest:
        return 'service_request';
      // case ServiceRequestOption.cateringRequest:
      //   return 'catering_request';
      // case ServiceRequestOption.laundryRequest:
      //   return 'laundry_request';
    }
  }
}
