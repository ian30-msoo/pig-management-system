// lib/services/mpesa_service.dart
// ─────────────────────────────────────────────────────────────────────────────
//  PigTrack MPesa Service — Safaricom Daraja API (Sandbox)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class MpesaResult {
  final bool success;
  final String? checkoutRequestId;
  final String? merchantRequestId;
  final String? responseCode;
  final String? responseDescription;
  final String? customerMessage;
  final String? errorMessage;

  const MpesaResult({
    required this.success,
    this.checkoutRequestId,
    this.merchantRequestId,
    this.responseCode,
    this.responseDescription,
    this.customerMessage,
    this.errorMessage,
  });
}

class MpesaQueryResult {
  final bool paid;
  final bool pending;
  final String? resultCode;
  final String? resultDesc;
  const MpesaQueryResult({required this.paid, required this.pending, this.resultCode, this.resultDesc});
}

class MpesaService {
  // ── Sandbox credentials ──────────────────────────────────────────────────
  static const String _consumerKey    = 'Dd40ClSErLakpwhj8KqzxyXBKCO5AxaAhARvht3Azgdv97w4';
  static const String _consumerSecret = 'ArHjAiKEpadoUUumAzJTCNRKWrwcpr2zdqV5HlkXvMAdyrmwBfvNXwf5SuUO6AIR';
  static const String _shortCode      = '174379';
  static const String _passKey        = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
  static const String _baseUrl        = 'https://sandbox.safaricom.co.ke';
  static const String _callbackUrl    = 'https://mydomain.com/mpesa-express-simulate/';

  // ── Get OAuth access token ────────────────────────────────────────────────
  static Future<String?> _getAccessToken() async {
    try {
      final credentials = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
      final response = await http.get(
        Uri.parse('$_baseUrl/oauth/v1/generate?grant_type=client_credentials'),
        headers: {'Authorization': 'Basic $credentials', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['access_token']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Generate password (base64 of shortcode+passkey+timestamp) ────────────
  static String _generatePassword(String timestamp) {
    final raw = '$_shortCode$_passKey$timestamp';
    return base64Encode(utf8.encode(raw));
  }

  // ── Generate timestamp YYYYMMDDHHmmss ─────────────────────────────────────
  static String _timestamp() {
    final now = DateTime.now();
    final y   = now.year.toString();
    final mo  = now.month.toString().padLeft(2, '0');
    final d   = now.day.toString().padLeft(2, '0');
    final h   = now.hour.toString().padLeft(2, '0');
    final mi  = now.minute.toString().padLeft(2, '0');
    final s   = now.second.toString().padLeft(2, '0');
    return '$y$mo$d$h$mi$s';
  }

  // ── Sanitize phone number to 254XXXXXXXXX format ──────────────────────────
  static String _sanitizePhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    if (phone.startsWith('0'))  return '254${phone.substring(1)}';
    if (phone.startsWith('+'))  return phone.substring(1);
    return phone;
  }

  // ── Initiate STK Push ─────────────────────────────────────────────────────
  static Future<MpesaResult> stkPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return const MpesaResult(success: false, errorMessage: 'Could not connect to M-PESA. Check your internet connection.');
      }

      final ts       = _timestamp();
      final password = _generatePassword(ts);
      final phone    = _sanitizePhone(phoneNumber);
      final amtInt   = amount.ceil(); // MPesa requires whole numbers

      final body = {
        'BusinessShortCode': _shortCode,
        'Password':          password,
        'Timestamp':         ts,
        'TransactionType':   'CustomerPayBillOnline',
        'Amount':            amtInt.toString(),
        'PartyA':            phone,
        'PartyB':            _shortCode,
        'PhoneNumber':       phone,
        'CallBackURL':       _callbackUrl,
        'AccountReference':  accountReference.length > 12 ? accountReference.substring(0, 12) : accountReference,
        'TransactionDesc':   transactionDesc.length > 13 ? transactionDesc.substring(0, 13) : transactionDesc,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpush/v1/processrequest'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final rc = data['ResponseCode']?.toString() ?? '';
        if (rc == '0') {
          return MpesaResult(
            success:            true,
            checkoutRequestId:  data['CheckoutRequestID']?.toString(),
            merchantRequestId:  data['MerchantRequestID']?.toString(),
            responseCode:       rc,
            responseDescription: data['ResponseDescription']?.toString(),
            customerMessage:    data['CustomerMessage']?.toString(),
          );
        }
        return MpesaResult(
          success: false,
          responseCode: rc,
          errorMessage: data['ResponseDescription']?.toString() ?? data['errorMessage']?.toString() ?? 'STK push failed.',
        );
      }

      // Parse error response
      final errMsg = data['errorMessage']?.toString()
          ?? data['ResponseDescription']?.toString()
          ?? 'M-PESA request failed (${response.statusCode}).';
      return MpesaResult(success: false, errorMessage: errMsg);

    } on TimeoutException {
      return const MpesaResult(success: false, errorMessage: 'M-PESA request timed out. Please check your internet and try again.');
    } catch (e) {
      return MpesaResult(success: false, errorMessage: 'Network error: $e');
    }
  }

  // ── Query STK Push status ─────────────────────────────────────────────────
  static Future<MpesaQueryResult> queryStatus({
    required String checkoutRequestId,
  }) async {
    try {
      final token = await _getAccessToken();
      if (token == null) return const MpesaQueryResult(paid: false, pending: true, resultDesc: 'Could not verify');

      final ts       = _timestamp();
      final password = _generatePassword(ts);

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpushquery/v1/query'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'BusinessShortCode': _shortCode,
          'Password':          password,
          'Timestamp':         ts,
          'CheckoutRequestID': checkoutRequestId,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rc   = data['ResultCode']?.toString() ?? '';

      if (rc == '0') return MpesaQueryResult(paid: true, pending: false, resultCode: rc, resultDesc: data['ResultDesc']?.toString());
      if (rc == '1032') return MpesaQueryResult(paid: false, pending: false, resultCode: rc, resultDesc: 'Transaction cancelled by user.');
      if (rc == '1037') return MpesaQueryResult(paid: false, pending: false, resultCode: rc, resultDesc: 'Request timed out on user side.');
      if (rc == '2001') return MpesaQueryResult(paid: false, pending: false, resultCode: rc, resultDesc: 'Wrong M-PESA PIN entered.');

      // Still processing
      return MpesaQueryResult(paid: false, pending: true, resultCode: rc, resultDesc: data['ResultDesc']?.toString());
    } catch (_) {
      return const MpesaQueryResult(paid: false, pending: true, resultDesc: 'Could not verify payment status.');
    }
  }
}