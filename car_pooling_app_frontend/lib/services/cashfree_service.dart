import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentcomponents/cfpaymentcomponent.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';

class CashfreeService {
  final CFPaymentGatewayService _cashfreeService = CFPaymentGatewayService();

  Function(String orderId)? onPaymentSuccess;
  Function(CFErrorResponse errorResponse, String orderId)? onPaymentError;
  Function()? onPaymentVerify;

  void init({
    Function(String orderId)? onSuccess,
    Function(CFErrorResponse errorResponse, String orderId)? onError,
  }) {
    onPaymentSuccess = onSuccess;
    onPaymentError = onError;
    _cashfreeService.setCallback(verifyPayment, handleError);
  }

  void verifyPayment(String orderId) {
    if (onPaymentSuccess != null) {
      onPaymentSuccess!(orderId);
    }
  }

  void handleError(CFErrorResponse errorResponse, String orderId) {
    if (onPaymentError != null) {
      onPaymentError!(errorResponse, orderId);
    }
  }

  Future<void> startPayment({
    required String sessionId,
    required String orderId,
    CFEnvironment environment = CFEnvironment.SANDBOX,
  }) async {
    try {
      var session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(orderId)
          .setPaymentSessionId(sessionId)
          .build();

      var theme = CFThemeBuilder()
          .setNavigationBarBackgroundColorColor("#3366FF")
          .setNavigationBarTextColor("#FFFFFF")
          .setButtonBackgroundColor("#3366FF")
          .setButtonTextColor("#FFFFFF")
          .setPrimaryTextColor("#000000")
          .setSecondaryTextColor("#000000")
          .build();

      var paymentComponent = CFPaymentComponentBuilder().setComponents([
        CFPaymentModes.UPI,
        CFPaymentModes.CARD,
        CFPaymentModes.WALLET,
        CFPaymentModes.NETBANKING,
      ]).build();

      var payment = CFDropCheckoutPaymentBuilder()
          .setSession(session)
          .setTheme(theme)
          .setPaymentComponent(paymentComponent)
          .build();

      _cashfreeService.doPayment(payment);
    } on CFException catch (e) {
if (onPaymentError != null) {
      }
    }
  }
}
