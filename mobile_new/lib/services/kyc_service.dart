import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class KycDocument {
  final String id;
  final String name;
  final String type;
  final String issuer;
  final DateTime issuedDate;
  final DateTime expiryDate;
  final String documentNumber;
  final Map<String, dynamic> metadata;
  final bool isVerified;

  KycDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.issuer,
    required this.issuedDate,
    required this.expiryDate,
    required this.documentNumber,
    required this.metadata,
    this.isVerified = false,
  });

  factory KycDocument.fromJson(Map<String, dynamic> json) {
    return KycDocument(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      issuer: json['issuer'] ?? '',
      issuedDate: DateTime.parse(json['issuedDate'] ?? DateTime.now().toIso8601String()),
      expiryDate: DateTime.parse(json['expiryDate'] ?? DateTime.now().add(Duration(days: 365)).toIso8601String()),
      documentNumber: json['documentNumber'] ?? '',
      metadata: json['metadata'] ?? {},
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'issuer': issuer,
      'issuedDate': issuedDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'documentNumber': documentNumber,
      'metadata': metadata,
      'isVerified': isVerified,
    };
  }
}

class KycVerificationResult {
  final bool isSuccessful;
  final String message;
  final KycDocument? document;
  final Map<String, dynamic>? extractedData;
  final List<String> errors;

  KycVerificationResult({
    required this.isSuccessful,
    required this.message,
    this.document,
    this.extractedData,
    this.errors = const [],
  });
}

class KycService {
  static KycService? _instance;
  static KycService get instance {
    _instance ??= KycService._internal();
    return _instance!;
  }

  KycService._internal();

  // DigiLocker API Configuration
  static const String _digiLockerBaseUrl = 'https://api.digilocker.gov.in';
  static const String _clientId = 'YOUR_DIGILOCKER_CLIENT_ID'; // Replace with actual client ID
  static const String _clientSecret = 'YOUR_DIGILOCKER_CLIENT_SECRET'; // Replace with actual client secret

  String? _accessToken;
  String? _userToken;

  // Initialize DigiLocker OAuth flow
  Future<String> initiateDigiLockerAuth() async {
    final authUrl = '$_digiLockerBaseUrl/oauth/authorize?'
        'response_type=code&'
        'client_id=$_clientId&'
        'redirect_uri=${Uri.encodeComponent('parttimepaise://digilocker/callback')}&'
        'scope=verified&'
        'state=${DateTime.now().millisecondsSinceEpoch}';

    if (await canLaunchUrl(Uri.parse(authUrl))) {
      await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication);
      return 'DigiLocker authentication initiated';
    } else {
      throw Exception('Could not launch DigiLocker authentication');
    }
  }

  // Handle DigiLocker OAuth callback
  Future<KycVerificationResult> handleDigiLockerCallback(String code) async {
    try {
      // Exchange authorization code for access token
      final tokenResponse = await http.post(
        Uri.parse('$_digiLockerBaseUrl/oauth/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': 'parttimepaise://digilocker/callback',
        },
      );

      if (tokenResponse.statusCode != 200) {
        return KycVerificationResult(
          isSuccessful: false,
          message: 'Failed to obtain access token',
          errors: ['Token exchange failed: ${tokenResponse.statusCode}'],
        );
      }

      final tokenData = json.decode(tokenResponse.body);
      _accessToken = tokenData['access_token'];
      _userToken = tokenData['user_token'];

      // Fetch user documents
      return await _fetchAndVerifyDocuments();
    } catch (e) {
      return KycVerificationResult(
        isSuccessful: false,
        message: 'DigiLocker authentication failed',
        errors: [e.toString()],
      );
    }
  }

  // Fetch and verify documents from DigiLocker
  Future<KycVerificationResult> _fetchAndVerifyDocuments() async {
    if (_accessToken == null || _userToken == null) {
      return KycVerificationResult(
        isSuccessful: false,
        message: 'Not authenticated with DigiLocker',
        errors: ['Missing access token'],
      );
    }

    try {
      // Fetch issued documents
      final documentsResponse = await http.get(
        Uri.parse('$_digiLockerBaseUrl/issued-docs'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'user_token': _userToken!,
        },
      );

      if (documentsResponse.statusCode != 200) {
        return KycVerificationResult(
          isSuccessful: false,
          message: 'Failed to fetch documents',
          errors: ['API request failed: ${documentsResponse.statusCode}'],
        );
      }

      final documentsData = json.decode(documentsResponse.body);
      final documents = documentsData['issued'] as List<dynamic>? ?? [];

      // Look for identity documents (Aadhaar, PAN, etc.)
      KycDocument? primaryDocument;
      final extractedData = <String, dynamic>{};

      for (var doc in documents) {
        final docType = doc['doctype']?.toString().toLowerCase() ?? '';

        if (docType.contains('aadhaar') || docType.contains('pan') || docType.contains('driving')) {
          // Download and verify the document
          final verificationResult = await _verifyDocument(doc);
          if (verificationResult.isSuccessful && verificationResult.document != null) {
            primaryDocument = verificationResult.document;
            extractedData.addAll(verificationResult.extractedData ?? {});
            break; // Use the first valid identity document
          }
        }
      }

      if (primaryDocument != null) {
        return KycVerificationResult(
          isSuccessful: true,
          message: 'KYC verification successful',
          document: primaryDocument,
          extractedData: extractedData,
        );
      } else {
        return KycVerificationResult(
          isSuccessful: false,
          message: 'No valid identity document found',
          errors: ['Please ensure you have Aadhaar, PAN, or Driving License in DigiLocker'],
        );
      }
    } catch (e) {
      return KycVerificationResult(
        isSuccessful: false,
        message: 'Document verification failed',
        errors: [e.toString()],
      );
    }
  }

  // Verify individual document
  Future<KycVerificationResult> _verifyDocument(Map<String, dynamic> docData) async {
    try {
      final docUri = docData['uri'];
      if (docUri == null) {
        return KycVerificationResult(
          isSuccessful: false,
          message: 'Document URI not available',
        );
      }

      // Download document (in a real implementation, you'd process the PDF/image)
      final downloadResponse = await http.get(
        Uri.parse(docUri),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'user_token': _userToken!,
        },
      );

      if (downloadResponse.statusCode != 200) {
        return KycVerificationResult(
          isSuccessful: false,
          message: 'Failed to download document',
        );
      }

      // Extract document data (simplified - in real implementation, use OCR/AI)
      final extractedData = await _extractDocumentData(docData, downloadResponse.bodyBytes);

      final document = KycDocument(
        id: docData['id'] ?? '',
        name: docData['name'] ?? '',
        type: docData['doctype'] ?? '',
        issuer: docData['issuer'] ?? '',
        issuedDate: DateTime.tryParse(docData['issued_date'] ?? '') ?? DateTime.now(),
        expiryDate: DateTime.tryParse(docData['expiry_date'] ?? '') ?? DateTime.now().add(Duration(days: 365)),
        documentNumber: extractedData['documentNumber'] ?? '',
        metadata: extractedData,
        isVerified: true,
      );

      return KycVerificationResult(
        isSuccessful: true,
        message: 'Document verified successfully',
        document: document,
        extractedData: extractedData,
      );
    } catch (e) {
      return KycVerificationResult(
        isSuccessful: false,
        message: 'Document verification failed',
        errors: [e.toString()],
      );
    }
  }

  // Extract data from document (simplified implementation)
  Future<Map<String, dynamic>> _extractDocumentData(Map<String, dynamic> docData, List<int> documentBytes) async {
    // In a real implementation, this would use OCR, AI, or DigiLocker's verification API
    // For now, we'll simulate data extraction based on document type

    final docType = docData['doctype']?.toString().toLowerCase() ?? '';
    final extractedData = <String, dynamic>{};

    if (docType.contains('aadhaar')) {
      extractedData.addAll({
        'documentType': 'aadhaar',
        'documentNumber': 'XXXX-XXXX-XXXX', // Would be extracted from OCR
        'name': docData['name'] ?? '',
        'dateOfBirth': '1990-01-01', // Would be extracted
        'address': 'Extracted Address', // Would be extracted
        'gender': 'M/F',
      });
    } else if (docType.contains('pan')) {
      extractedData.addAll({
        'documentType': 'pan',
        'documentNumber': 'XXXXX0000X', // Would be extracted
        'name': docData['name'] ?? '',
        'dateOfBirth': '1990-01-01',
        'fatherName': 'Father Name',
      });
    } else if (docType.contains('driving')) {
      extractedData.addAll({
        'documentType': 'driving_license',
        'documentNumber': 'DL-XX-XXXXXXXXXX', // Would be extracted
        'name': docData['name'] ?? '',
        'dateOfBirth': '1990-01-01',
        'address': 'Extracted Address',
        'validity': docData['expiry_date'] ?? '',
      });
    }

    return extractedData;
  }

  // Check if user has completed KYC
  Future<bool> isKycCompleted(String userId) async {
    // In a real implementation, check Firestore for KYC status
    // For now, return false
    return false;
  }

  // Get KYC status for user
  Future<Map<String, dynamic>?> getKycStatus(String userId) async {
    // In a real implementation, fetch from Firestore
    return null;
  }

  // Alternative KYC methods for users without DigiLocker
  Future<KycVerificationResult> uploadDocumentForVerification(
    String documentType,
    List<int> documentBytes,
    Map<String, dynamic> userProvidedData,
  ) async {
    // In a real implementation, this would upload to a verification service
    // For now, simulate verification
    await Future.delayed(Duration(seconds: 2)); // Simulate processing time

    final document = KycDocument(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: userProvidedData['name'] ?? '',
      type: documentType,
      issuer: 'Manual Upload',
      issuedDate: DateTime.now(),
      expiryDate: DateTime.now().add(Duration(days: 365)),
      documentNumber: userProvidedData['documentNumber'] ?? '',
      metadata: userProvidedData,
      isVerified: true, // In real implementation, this would be false until manual review
    );

    return KycVerificationResult(
      isSuccessful: true,
      message: 'Document uploaded successfully. Verification pending.',
      document: document,
      extractedData: userProvidedData,
    );
  }
}