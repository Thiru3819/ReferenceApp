import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'notification_helper.dart';

void main() {
  runApp(const TempleQueueApp());
}

class TempleQueueApp extends StatefulWidget {
  const TempleQueueApp({super.key});

  @override
  State<TempleQueueApp> createState() => _TempleQueueAppState();
}

class _TempleQueueAppState extends State<TempleQueueApp> {
  final TempleQueueStore store = TempleQueueStore();
  late final Future<void> _initialization = store.initialize();

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  ThemeData _buildTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF800000), // Deep Maroon
        primary: const Color(0xFF800000),
        secondary: const Color(0xFFD4AF37), // Temple Gold
        tertiary: const Color(0xFFF4A460), // Sandalwood
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFDF0), // Sandalwood Cream
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFAF2E0),
        labelStyle: const TextStyle(color: Color(0xFF800000)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6C280)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF800000), width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF800000),
          foregroundColor: const Color(0xFFFFD700),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF800000),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFFAF2E0),
        disabledColor: Colors.grey,
        selectedColor: const Color(0xFF800000),
        secondarySelectedColor: const Color(0xFF800000),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE6C280)),
        ),
        labelStyle: const TextStyle(color: Color(0xFF800000), fontWeight: FontWeight.bold),
      ),
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: const Color(0xFF4A0E17),
        displayColor: const Color(0xFF4A0E17),
        fontFamily: 'Noto Sans Tamil',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _buildTheme(context);
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF800000)),
                    SizedBox(height: 16),
                    Text(
                      'அருள் வரிசை - துவக்கமாகிறது...',
                      style: TextStyle(
                        color: Color(0xFF800000),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'அருள் வரிசை (Arul Varisai)',
          theme: theme,
          home: TempleLandingPage(store: store),
        );
      },
    );
  }
}

class TempleMember {
  const TempleMember({
    required this.name,
    required this.username,
    required this.password,
    this.smsPhone = '',
  });

  final String name;
  final String username;
  final String password;
  final String smsPhone;
}

class TextbeeSmsResult {
  const TextbeeSmsResult({
    required this.sent,
    required this.statusCode,
    required this.message,
  });

  final bool sent;
  final int? statusCode;
  final String message;
}

class TextbeeSmsService {
  TextbeeSmsService({http.Client? client}) : _client = client ?? http.Client();

  static const String apiKey = String.fromEnvironment('TEXTBEE_API_KEY');
  static const String deviceId = String.fromEnvironment('TEXTBEE_DEVICE_ID');

  final http.Client _client;

  bool get isConfigured => apiKey.isNotEmpty && deviceId.isNotEmpty;

  Future<TextbeeSmsResult> sendSms({
    required List<String> recipients,
    required String message,
  }) async {
    final cleanRecipients = recipients
        .map((recipient) => recipient.trim())
        .where((recipient) => recipient.isNotEmpty)
        .toList();

    if (cleanRecipients.isEmpty) {
      return const TextbeeSmsResult(
        sent: false,
        statusCode: null,
        message: 'No SMS recipients configured.',
      );
    }

    if (!isConfigured) {
      return const TextbeeSmsResult(
        sent: false,
        statusCode: null,
        message: 'Textbee API key or device id is missing.',
      );
    }

    final uri = Uri.https(
      'api.textbee.dev',
      '/api/v1/gateway/devices/$deviceId/send-sms',
    );

    try {
      final response = await _client.post(
        uri,
        headers: <String, String>{
          'content-type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode(<String, dynamic>{
          'recipients': cleanRecipients,
          'message': message,
        }),
      );

      final sent = response.statusCode >= 200 && response.statusCode < 300;
      return TextbeeSmsResult(
        sent: sent,
        statusCode: response.statusCode,
        message: sent ? 'SMS sent.' : response.body,
      );
    } catch (error) {
      return TextbeeSmsResult(
        sent: false,
        statusCode: null,
        message: error.toString(),
      );
    }
  }
}

class TempleNotification {
  const TempleNotification({
    required this.title,
    required this.message,
    required this.memberName,
    required this.createdAt,
  });

  final String title;
  final String message;
  final String memberName;
  final DateTime createdAt;
}

class RegistrationRecord {
  RegistrationRecord({
    required this.queueNumber,
    required this.memoryCode,
    required this.name,
    required this.phone,
    required this.referenceMember,
    required this.ticketCount,
    required this.groupSize,
    required this.entryIds,
    required this.createdAt,
    this.spiritualLevel = 1,
  }) : status = 'அனுமதிக்கு காத்திருக்கிறது';

  final String queueNumber;
  final String memoryCode;
  final String name;
  final String phone;
  final String referenceMember;
  final int ticketCount;
  final int groupSize;
  final List<String> entryIds;
  final DateTime createdAt;
  int spiritualLevel;
  String status;
}

class TempleQueueStore {
  static const String templeOfficeSmsPhone = String.fromEnvironment(
    'TEMPLE_OFFICE_SMS_PHONE',
  );

  static const List<TempleMember> members = [
    TempleMember(
      name: 'ஆசான் அகத்தியர்',
      username: 'agathiyar',
      password: 'guru@agathiyar',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_AGATHIYAR_PHONE'),
    ),
    TempleMember(
      name: 'ஆசான் திருமூலர்',
      username: 'thirumoolar',
      password: 'guru@thirumoolar',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_THIRUMOOLAR_PHONE'),
    ),
    TempleMember(
      name: 'ஆசான் இராமானுஜர்',
      username: 'ramanujar',
      password: 'guru@ramanujar',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_RAMANUJAR_PHONE'),
    ),
    TempleMember(
      name: 'ஆசான் வள்ளலார்',
      username: 'vallalar',
      password: 'guru@vallalar',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_VALLALAR_PHONE'),
    ),
    TempleMember(
      name: 'ஆசான் ரமணர்',
      username: 'ramanar',
      password: 'guru@ramanar',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_RAMANAR_PHONE'),
    ),
    TempleMember(
      name: 'ஆசான் பட்டினத்தார்',
      username: 'pattinathar',
      password: 'guru@pattinathar',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_PATTINATHAR_PHONE'),
    ),
  ];

  final List<RegistrationRecord> registrations = [];
  final List<TempleNotification> notifications = [];
  final TextbeeSmsService _smsService = TextbeeSmsService();
  final Random _random = Random.secure();
  int nextQueueNumber = 1;
  bool _firebaseEnabled = false;
  
  String fastingTitle = '';
  DateTime? fastingTime;

  StreamSubscription? _registrationsSubscription;
  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _fastingSubscription;

  bool get isFirebaseEnabled => _firebaseEnabled;

  Stream<QuerySnapshot<Map<String, dynamic>>> get registrationsCollectionStream =>
      _registrationsCollection.snapshots();

  RegistrationRecord registrationFromMapWrapper(Map<String, dynamic> data) =>
      _registrationFromMap(data);

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));
      _firebaseEnabled = true;
    } catch (error) {
      debugPrint('Firebase initialization failed: $error');
      _firebaseEnabled = false;
      return;
    }

    await _runFirebaseTask(_seedTempleMembers);
    await _runFirebaseTask(_loadFromFirebase);
    _setupFirebaseListeners();
  }

  void _setupFirebaseListeners() {
    if (!_firebaseEnabled) {
      return;
    }

    _fastingSubscription = FirebaseFirestore.instance
        .collection('temple_queue_fasting')
        .doc('current')
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            fastingTitle = (data['title'] as String?) ?? '';
            final timeStr = data['time'] as String?;
            fastingTime = timeStr != null ? DateTime.tryParse(timeStr) : null;
            debugPrint('Fasting event updated in real-time: $fastingTitle');
          }
        }
      },
      onError: (error) => debugPrint('Error listening to fasting details: $error'),
    );
  }

  void startNotificationListener(
    TempleMember member,
    void Function(TempleNotification) onNewNotification,
  ) {
    _notificationsSubscription?.cancel();
    if (!_firebaseEnabled) {
      return;
    }

    final startTime = DateTime.now();

    _notificationsSubscription = _notificationsCollection
        .snapshots()
        .listen((snapshot) {
      bool hasNew = false;
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final notification = _notificationFromMap(data);
            
            if (notification.createdAt.isAfter(startTime)) {
              if (notification.memberName == member.name ||
                  notification.memberName == 'Temple Office') {
                
                PlatformNotificationHelper.showNotification(
                  notification.title,
                  notification.message,
                );

                if (!notifications.any((n) => n.createdAt == notification.createdAt && n.message == notification.message)) {
                  notifications.insert(0, notification);
                  hasNew = true;
                }
              }
            }
          }
        }
      }
      
      if (hasNew) {
        onNewNotification(notifications.first);
      }
    });
  }

  void stopNotificationListener() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
  }

  void dispose() {
    _registrationsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _fastingSubscription?.cancel();
  }

  Future<RegistrationRecord> registerVisitor({
    required String name,
    required String phone,
    required String referenceMember,
    required int ticketCount,
  }) async {
    RegistrationRecord? registration;
    int allocatedQueueNumber = nextQueueNumber;
    String queueNumber = '';
    String memoryCode = '';
    final groupSize = ticketCount * 2;

    if (_firebaseEnabled) {
      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final stateSnapshot = await transaction.get(_stateDocument);
          int currentNext = 1;
          if (stateSnapshot.exists) {
            currentNext = (stateSnapshot.data()?['nextQueueNumber'] as int?) ?? 1;
          }

          allocatedQueueNumber = currentNext;
          queueNumber = 'Q-${allocatedQueueNumber.toString().padLeft(3, '0')}';
          
          final randomCode = (_random.nextInt(9000) + 1000).toString();
          memoryCode = randomCode;

          final entryIds = List<String>.generate(
            groupSize,
            (index) => '$queueNumber-${(index + 1).toString().padLeft(2, '0')}',
          );

          registration = RegistrationRecord(
            queueNumber: queueNumber,
            memoryCode: memoryCode,
            name: name,
            phone: phone,
            referenceMember: referenceMember,
            ticketCount: ticketCount,
            groupSize: groupSize,
            entryIds: entryIds,
            createdAt: DateTime.now(),
            spiritualLevel: 1,
          );

          transaction.set(_stateDocument, <String, dynamic>{
            'nextQueueNumber': currentNext + 1,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          }, SetOptions(merge: true));

          transaction.set(_registrationsCollection.doc(queueNumber), _registrationToMap(registration!));

          final userNotification = TempleNotification(
            title: 'புதிய சாதகர் பதிவு',
            message:
                '$name அடியார் $ticketCount இணைப்பில் $groupSize உறுப்பினர்களுடன் இணைந்தார். அருள் எண் $queueNumber மற்றும் ஞான குறியீடு $memoryCode அனுமதிக்கு காத்திருக்கிறது.',
            memberName: referenceMember,
            createdAt: registration!.createdAt,
          );
          final officeNotification = TempleNotification(
            title: 'நிர்வாக அறிவிப்பு',
            message:
                '$name அடியார் அருள் வரிசையில் $queueNumber மற்றும் ஞான குறியீடு $memoryCode உடன் வெற்றிகரமாக இணைந்துள்ளார்.',
            memberName: 'Temple Office',
            createdAt: registration!.createdAt,
          );

          transaction.set(_notificationsCollection.doc(), _notificationToMap(userNotification));
          transaction.set(_notificationsCollection.doc(), _notificationToMap(officeNotification));
        }).timeout(const Duration(seconds: 8));

        if (registration != null) {
          nextQueueNumber = allocatedQueueNumber + 1;
          registrations.insert(0, registration!);

          final userNotification = TempleNotification(
            title: 'புதிய சாதகர் பதிவு',
            message:
                '$name அடியார் $ticketCount இணைப்பில் $groupSize உறுப்பினர்களுடன் இணைந்தார். அருள் எண் $queueNumber மற்றும் ஞான குறியீடு $memoryCode அனுமதிக்கு காத்திருக்கிறது.',
            memberName: referenceMember,
            createdAt: registration!.createdAt,
          );
          final officeNotification = TempleNotification(
            title: 'நிர்வாக அறிவிப்பு',
            message:
                '$name அடியார் அருள் வரிசையில் $queueNumber மற்றும் ஞான குறியீடு $memoryCode உடன் வெற்றிகரமாக இணைந்துள்ளார்.',
            memberName: 'Temple Office',
            createdAt: registration!.createdAt,
          );

          notifications.insert(0, officeNotification);
          notifications.insert(0, userNotification);
        }
      } catch (error) {
        debugPrint('Firestore transaction failed, falling back to local: $error');
      }
    }

    if (registration == null) {
      allocatedQueueNumber = nextQueueNumber;
      queueNumber = 'Q-${allocatedQueueNumber.toString().padLeft(3, '0')}';
      memoryCode = _generateMemoryCode();
      final entryIds = List<String>.generate(
        groupSize,
        (index) => '$queueNumber-${(index + 1).toString().padLeft(2, '0')}',
      );

      registration = RegistrationRecord(
        queueNumber: queueNumber,
        memoryCode: memoryCode,
        name: name,
        phone: phone,
        referenceMember: referenceMember,
        ticketCount: ticketCount,
        groupSize: groupSize,
        entryIds: entryIds,
        createdAt: DateTime.now(),
        spiritualLevel: 1,
      );

      registrations.insert(0, registration!);
      final userNotification = TempleNotification(
        title: 'புதிய சாதகர் பதிவு',
        message:
            '$name அடியார் $ticketCount இணைப்பில் $groupSize உறுப்பினர்களுடன் இணைந்தார். அருள் எண் $queueNumber மற்றும் ஞான குறியீடு $memoryCode அனுமதிக்கு காத்திருக்கிறது.',
        memberName: referenceMember,
        createdAt: registration!.createdAt,
      );
      final officeNotification = TempleNotification(
        title: 'நிர்வாக அறிவிப்பு',
        message:
            '$name அடியார் அருள் வரிசையில் $queueNumber மற்றும் ஞான குறியீடு $memoryCode உடன் வெற்றிகரமாக இணைந்துள்ளார்.',
        memberName: 'Temple Office',
        createdAt: registration!.createdAt,
      );

      notifications.insert(0, officeNotification);
      notifications.insert(0, userNotification);
      nextQueueNumber++;

      _saveRegistration(registration!);
      _saveNotification(userNotification);
      _saveNotification(officeNotification);
      _saveQueueState();
    }

    _sendRegistrationSmsNotifications(
      name: name,
      phone: phone,
      queueNumber: queueNumber,
      memoryCode: memoryCode,
      referenceMember: referenceMember,
      ticketCount: ticketCount,
      groupSize: groupSize,
    );

    return registration!;
  }

  Future<void> _sendRegistrationSmsNotifications({
    required String name,
    required String phone,
    required String queueNumber,
    required String memoryCode,
    required String referenceMember,
    required int ticketCount,
    required int groupSize,
  }) async {
    try {
      final member = members.firstWhereOrNull((m) => m.name == referenceMember);
      if (member != null && member.smsPhone.isNotEmpty) {
        final message = 'வணக்கம் ${member.name}! சாதகர் $name ($phone) உங்களுடைய அருள் வரிசையில் இணைந்துள்ளார்.\n'
            'அருள் எண்: $queueNumber\n'
            'ஞான குறியீடு: $memoryCode\n'
            'இணைப்புகள்: $ticketCount ($groupSize நபர்)';
        final result = await _smsService.sendSms(
          recipients: [member.smsPhone],
          message: message,
        );
        debugPrint('SMS sent: ${result.sent}');
      }
    } catch (e) {
      debugPrint('SMS error: $e');
    }
  }

  Future<void> persistLogin(TempleMember member) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_username', member.username);
      await prefs.setInt('login_time_ms', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Persist login failed: $e');
    }
  }

  Future<void> clearPersistedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_in_username');
      await prefs.remove('login_time_ms');
    } catch (e) {
      debugPrint('Clear login failed: $e');
    }
  }

  Future<TempleMember?> getPersistedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('logged_in_username');
      final loginTimeMs = prefs.getInt('login_time_ms');
      
      if (username != null && loginTimeMs != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        const oneDayMs = 24 * 60 * 60 * 1000;
        if (now - loginTimeMs < oneDayMs) {
          return members.firstWhereOrNull((m) => m.username == username);
        } else {
          await clearPersistedLogin();
        }
      }
    } catch (e) {
      debugPrint('Load login failed: $e');
    }
    return null;
  }

  TempleMember? authenticateMember(String username, String password) {
    final normalizedUsername = username.trim().toLowerCase();
    return members.firstWhereOrNull(
      (member) =>
          member.username.toLowerCase() == normalizedUsername &&
          member.password == password,
    );
  }

  RegistrationRecord? findRegistrationByLogin(
    String phone,
    String queueOrCode,
  ) {
    final normalizedIdentifier = queueOrCode.trim().toUpperCase();
    return registrations.firstWhereOrNull(
      (record) =>
          record.phone == phone.trim() &&
          (record.queueNumber.toUpperCase() == normalizedIdentifier ||
              record.memoryCode.toUpperCase() == normalizedIdentifier),
    );
  }

  Future<void> updateRegistrationStatus(
    RegistrationRecord record,
    String status,
  ) async {
    record.status = status;
    if (!_firebaseEnabled) {
      return;
    }

    try {
      await _registrationsCollection.doc(record.queueNumber).update(
        <String, dynamic>{'status': status},
      ).timeout(const Duration(seconds: 5));
    } catch (error) {
      debugPrint('Error updating registration status: $error');
    }
  }

  Future<void> elevateSpiritualLevel(RegistrationRecord record) async {
    if (record.spiritualLevel >= 10) return;
    record.spiritualLevel++;
    
    if (record.spiritualLevel == 10) {
      record.status = 'ஆசான் நிலை (முதிர்ச்சி)';
    }

    if (_firebaseEnabled) {
      try {
        await _registrationsCollection.doc(record.queueNumber).update(
          <String, dynamic>{
            'spiritualLevel': record.spiritualLevel,
            'status': record.status,
          },
        ).timeout(const Duration(seconds: 5));
      } catch (error) {
        debugPrint('Error updating spiritual level: $error');
      }
    }

    try {
      final message = 'அன்பு ${record.name}, உங்கள் குருநாதர் உங்கள் ஞான நிலையை ${record.spiritualLevel} ஆக உயர்த்தியுள்ளார். உன்னுள் இருக்கும் இறைவனை நோக்கி முன்னேறுங்கள்!';
      final result = await _smsService.sendSms(
        recipients: [record.phone],
        message: message,
      );
      debugPrint('Progress SMS sent: ${result.sent}');
    } catch (e) {
      debugPrint('Error sending progress SMS: $e');
    }
  }

  Future<void> updateFastingEvent(String title, DateTime time) async {
    fastingTitle = title;
    fastingTime = time;
    
    if (!_firebaseEnabled) return;
    try {
      await FirebaseFirestore.instance.collection('temple_queue_fasting').doc('current').set({
        'title': title,
        'time': time.toIso8601String(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Error writing fasting: $e');
    }
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Future<void> _loadFromFirebase() async {
    if (!_firebaseEnabled) {
      return;
    }

    try {
      final stateSnapshot = await _stateDocument.get().timeout(const Duration(seconds: 4));
      if (stateSnapshot.exists) {
        final data = stateSnapshot.data();
        nextQueueNumber = (data?['nextQueueNumber'] as int?) ?? 1;
      }

      final registrationsSnapshot = await _registrationsCollection.get().timeout(const Duration(seconds: 4));
      final loadedRegistrations =
          registrationsSnapshot.docs
              .map((doc) => _registrationFromMap(doc.data()))
              .toList()
            ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

      final notificationsSnapshot = await _notificationsCollection.get().timeout(const Duration(seconds: 4));
      final loadedNotifications =
          notificationsSnapshot.docs
              .map((doc) => _notificationFromMap(doc.data()))
              .toList()
            ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

      final fastingSnapshot = await FirebaseFirestore.instance
          .collection('temple_queue_fasting')
          .doc('current')
          .get()
          .timeout(const Duration(seconds: 4));
      if (fastingSnapshot.exists) {
        final data = fastingSnapshot.data();
        fastingTitle = (data?['title'] as String?) ?? '';
        final timeStr = data?['time'] as String?;
        fastingTime = timeStr != null ? DateTime.tryParse(timeStr) : null;
      }

      registrations
        ..clear()
        ..addAll(loadedRegistrations);
      notifications
        ..clear()
        ..addAll(loadedNotifications);
    } catch (e) {
      debugPrint('Error loading from Firebase (timeout or failure): $e');
    }
  }

  Future<void> _saveRegistration(RegistrationRecord registration) async {
    if (!_firebaseEnabled) {
      return;
    }

    try {
      await _registrationsCollection
          .doc(registration.queueNumber)
          .set(_registrationToMap(registration))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Error saving registration: $e');
    }
  }

  Future<void> _seedTempleMembers() async {
    if (!_firebaseEnabled) {
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final createdAt = Timestamp.fromDate(DateTime.now());
      for (final member in members) {
        batch.set(_membersCollection.doc(member.username), <String, dynamic>{
          'name': member.name,
          'username': member.username,
          'password': member.password,
          'status': 'Active',
          'role': 'Temple member',
          'createdAt': createdAt,
        }, SetOptions(merge: true));
      }
      await batch.commit().timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Error seeding temple members (timeout or failure): $e');
    }
  }

  Future<void> _saveNotification(TempleNotification notification) async {
    if (!_firebaseEnabled) {
      return;
    }

    try {
      await _notificationsCollection
          .add(_notificationToMap(notification))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  Future<void> _saveQueueState() async {
    if (!_firebaseEnabled) {
      return;
    }

    try {
      await _stateDocument.set(<String, dynamic>{
        'nextQueueNumber': nextQueueNumber,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Error saving queue state: $e');
    }
  }

  Future<void> _runFirebaseTask(Future<void> Function() task) async {
    try {
      await task();
    } catch (error) {
      debugPrint('Firebase task failed: $error');
    }
  }

  CollectionReference<Map<String, dynamic>> get _registrationsCollection =>
      FirebaseFirestore.instance.collection('temple_queue_registrations');

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      FirebaseFirestore.instance.collection('temple_queue_notifications');

  CollectionReference<Map<String, dynamic>> get _membersCollection =>
      FirebaseFirestore.instance.collection('temple_members');

  DocumentReference<Map<String, dynamic>> get _stateDocument =>
      FirebaseFirestore.instance
          .collection('temple_queue_state')
          .doc('current');

  String _generateMemoryCode() {
    String code;
    do {
      code = (_random.nextInt(9000) + 1000).toString();
    } while (registrations.any((record) => record.memoryCode == code));
    return code;
  }

  Map<String, dynamic> _registrationToMap(RegistrationRecord record) {
    return <String, dynamic>{
      'queueNumber': record.queueNumber,
      'memoryCode': record.memoryCode,
      'name': record.name,
      'phone': record.phone,
      'referenceMember': record.referenceMember,
      'ticketCount': record.ticketCount,
      'groupSize': record.groupSize,
      'entryIds': record.entryIds,
      'createdAt': Timestamp.fromDate(record.createdAt),
      'status': record.status,
      'type': 'Visitor',
      'spiritualLevel': record.spiritualLevel,
    };
  }

  Map<String, dynamic> _notificationToMap(TempleNotification notification) {
    return <String, dynamic>{
      'title': notification.title,
      'message': notification.message,
      'memberName': notification.memberName,
      'createdAt': Timestamp.fromDate(notification.createdAt),
    };
  }

  RegistrationRecord _registrationFromMap(Map<String, dynamic> data) {
    return RegistrationRecord(
      queueNumber: (data['queueNumber'] as String?) ?? '',
      memoryCode: (data['memoryCode'] as String?) ?? _generateMemoryCode(),
      name: (data['name'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      referenceMember: (data['referenceMember'] as String?) ?? '',
      ticketCount: (data['ticketCount'] as num?)?.toInt() ?? 0,
      groupSize: (data['groupSize'] as num?)?.toInt() ?? 0,
      entryIds: data['entryIds'] is List
          ? (data['entryIds'] as List<dynamic>)
              .map((value) => value.toString())
              .toList()
          : [],
      createdAt: _parseDateTime(data['createdAt']),
      spiritualLevel: (data['spiritualLevel'] as num?)?.toInt() ?? 1,
    )..status = (data['status'] as String?) ?? 'Waiting approval';
  }

  TempleNotification _notificationFromMap(Map<String, dynamic> data) {
    return TempleNotification(
      title: (data['title'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      memberName: (data['memberName'] as String?) ?? '',
      createdAt: _parseDateTime(data['createdAt']),
    );
  }
}

class TempleLandingPage extends StatelessWidget {
  const TempleLandingPage({super.key, required this.store});

  final TempleQueueStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A0E17), Color(0xFF800000), Color(0xFF6B1D2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                children: [
                  _HeroBanner(
                    title: 'அருள் வரிசை',
                    subtitle: 'குரு-சிஷ்ய பரம்பரை ஆன்மீகப் பலகை மற்றும் தியான கண்காணிப்பு தளம்.',
                    totalRegistrations: store.registrations.length,
                    totalNotifications: store.notifications.length,
                    nextQueueNumber:
                        'Q-${store.nextQueueNumber.toString().padLeft(3, '0')}',
                  ),
                  const SizedBox(height: 24),
                  _SectionCard(
                    title: 'ஆன்மீக நுழைவாயில்',
                    subtitle: 'உங்கள் தற்போதைய ஆன்மீகப் பயணத்தைத் தேர்வுசெய்யவும்.',
                    child: Column(
                      children: [
                        _NavigationTile(
                          key: const ValueKey('nav_user_registration'),
                          title: 'சாதகர் பதிவு (Seeker Registration)',
                          message: 'ஆசானின் அருள் வரிசையில் அடியாராக இணையுங்கள்.',
                          icon: Icons.how_to_reg,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    UserRegistrationPage(store: store),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _NavigationTile(
                          key: const ValueKey('nav_user_profile'),
                          title: 'சாதகரின் சுயவிவரம் (Seeker Profile)',
                          message: 'உங்கள் தற்போதைய அருள் நிலை மற்றும் தியானப் பலகையைத் திறக்கவும்.',
                          icon: Icons.brightness_high,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UserProfilePage(store: store),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _NavigationTile(
                          key: const ValueKey('nav_temple_members'),
                          title: 'ஆசான்கள் தளம் (Aasan Dashboard)',
                          message: 'குருவின் தியானக் கட்டுப்பாட்டு பலகை மற்றும் சீடர்களின் நிலைகள்.',
                          icon: Icons.spa,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TempleMemberPage(store: store),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UserRegistrationPage extends StatefulWidget {
  const UserRegistrationPage({super.key, required this.store});

  final TempleQueueStore store;

  @override
  State<UserRegistrationPage> createState() => _UserRegistrationPageState();
}

class _UserRegistrationPageState extends State<UserRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedReferenceMember = TempleQueueStore.members.first.name;
  int _ticketCount = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('சாதகர் பதிவு'),
        backgroundColor: const Color(0xFF800000),
        foregroundColor: const Color(0xFFFFD700),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionCard(
            title: 'அருள் வரிசையில் இணைதல்',
            subtitle:
                'ஆசானைத் தேர்ந்தெடுத்து அருள் வரிசையில் உங்களுக்கான இடத்தைப் பெறுக.',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const ValueKey('registration_name'),
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'முழுப் பெயர் (Name)',
                      prefixIcon: Icon(Icons.person, color: Color(0xFF800000)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'உங்கள் பெயரை உள்ளிடவும்'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const ValueKey('registration_phone'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'அலைபேசி எண் (Mobile Number)',
                      prefixIcon: Icon(Icons.phone, color: Color(0xFF800000)),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 8
                        ? 'சரியான அலைபேசி எண்ணை உள்ளிடவும்'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('registration_reference'),
                    initialValue: _selectedReferenceMember,
                    decoration: const InputDecoration(
                      labelText: 'குரு / ஆசான் தேர்வு (Aasan)',
                      prefixIcon: Icon(Icons.menu_book, color: Color(0xFF800000)),
                    ),
                    items: TempleQueueStore.members
                        .map<DropdownMenuItem<String>>(
                          (member) => DropdownMenuItem<String>(
                            value: member.name,
                            child: Text(member.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedReferenceMember = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _StepperCard(
                    label: 'இணைப்புகள் (Spiritual Connections)',
                    value: _ticketCount.toString(),
                    hint: '1 இணைப்பு = 2 சீடர்கள்',
                    onAdd: () => setState(() => _ticketCount++),
                    onRemove: _ticketCount > 1
                        ? () => setState(() => _ticketCount--)
                        : null,
                    addKey: const ValueKey('ticket_add'),
                    removeKey: const ValueKey('ticket_remove'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const ValueKey('register_submit'),
                    onPressed: () => _submitRegistration(),
                    icon: const Icon(Icons.brightness_low),
                    label: const Text('அருள் வரிசையில் இணை'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRegistration() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final registration = await widget.store.registerVisitor(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      referenceMember: _selectedReferenceMember,
      ticketCount: _ticketCount,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF800000),
        content: Text(
          'அருள் எண் ${registration.queueNumber} சாதகர் ${registration.name} பெயருக்கு ஒதுக்கப்பட்டது!',
          style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
        ),
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UserProfilePage(
          store: widget.store,
          initialRegistration: registration,
        ),
      ),
    );
  }
}

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({
    super.key,
    required this.store,
    this.initialRegistration,
  });

  final TempleQueueStore store;
  final RegistrationRecord? initialRegistration;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _loginFormKey = GlobalKey<FormState>();
  final _profilePhoneController = TextEditingController();
  final _profileQueueController = TextEditingController();
  RegistrationRecord? _activeUser;
  StreamSubscription? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _activeUser = widget.initialRegistration;
    if (_activeUser != null) {
      _profilePhoneController.text = _activeUser!.phone;
      _profileQueueController.text = _activeUser!.queueNumber;
      _startLiveProfileListener();
    }
  }

  void _startLiveProfileListener() {
    _profileSubscription?.cancel();
    if (!widget.store.isFirebaseEnabled || _activeUser == null) return;
    
    try {
      _profileSubscription = widget.store.registrationsCollectionStream.listen((snapshot) {
        final match = snapshot.docs
            .map((doc) => widget.store.registrationFromMapWrapper(doc.data()))
            .firstWhereOrNull((record) => record.queueNumber == _activeUser!.queueNumber);
        
        if (match != null && mounted) {
          setState(() {
            _activeUser = match;
          });
        }
      });
    } catch (e) {
      debugPrint('Error profile stream: $e');
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _profilePhoneController.dispose();
    _profileQueueController.dispose();
    super.dispose();
  }

  String _getVerseForLevel(int level) {
    switch (level) {
      case 1:
        return '“அன்பும் சிவமும் இரண்டென்பர் அறிவிலார்...\nஅன்பே சிவமாவது ஆரும் அறிந்திலாரே.”\n- திருமூலர் (திருமந்திரம்)';
      case 2:
        return '“ஒன்றே குலமும் ஒருவனே தேவனும்...\nநன்றே நினைமின் நமனில்லை நாணாமே.”\n- திருமூலர் (திருமந்திரம்)';
      case 3:
        return '“தானம் தவம்இரண்டும் தங்கா வியனுலகம்...\nவானம் வழங்காது எனின்.”\n- திருவள்ளுவர் (திருக்குறள்)';
      case 4:
        return '“அறிவற்றங் காக்குங் கருவி செறுவார்க்கும்...\nஉள்ளழிக்க லாகா அரண்.”\n- திருவள்ளுவர் (திருக்குறள்)';
      case 5:
        return '“எப்பொருள் எத்தன்மைத் தாயினும் அப்பொருள்...\nமெய்ப்பொருள் காண்ப தறிவு.”\n- திருவள்ளுவர் (திருக்குறள்)';
      case 6:
        return '“ஒன்றே பரமன் உலகங்கள் ஏழினுக்கு...\nஅன்றே அருளிய மாமறை ஓதிடும்.”\n- திருமூலர் (திருமந்திரம்)';
      case 7:
        return '“உடம்பார் அழியின் உயிரார் அழிவர்...\nதிடம்பட மெய்ஞ்ஞானம் சேரவும் மாட்டார்.”\n- திருமூலர் (திருமந்திரம்)';
      case 8:
        return '“உடம்பினை முன்னம் இழுக்கென்று இருந்தேன்...\nஉடம்பினுக் குள்ளே உறுபொருள் கண்டேன்.”\n- திருமூலர் (திருமந்திரம்)';
      case 9:
        return '“உள்ளம் பெருங்கோயில் ஊனுடம்பு ஆலயம்...\nவள்ளல் பிரானார்க்கு வாய்கோபுர வாசல்.”\n- திருமூலர் (திருமந்திரம்)';
      case 10:
        return '“குருவே சிவமெனக் கூறினன் நந்தி...\nகுருவே சிவமாவது ஆரும் அறிந்திலாரே.”\n- திருமூலர் (திருமந்திரம்)';
      default:
        return '“அன்பே சிவம்.”';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = _activeUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ஆன்மீக சுயவிவரம்'),
        backgroundColor: const Color(0xFF800000),
        foregroundColor: const Color(0xFFFFD700),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (activeUser != null && widget.store.fastingTime != null && widget.store.fastingTitle.isNotEmpty) ...[
            _FastingCountdownWidget(
              title: widget.store.fastingTitle,
              targetTime: widget.store.fastingTime!,
            ),
            const SizedBox(height: 16),
          ],
          _SectionCard(
            title: activeUser == null
                ? 'உங்கள் அருள் நிலையைத் திறக்கவும்'
                : 'ஆன்மீக அனுமதி அட்டை (Spiritual Pass)',
            subtitle: activeUser == null
                ? 'அலைபேசி எண் மற்றும் அருள் எண் / ஞான குறியீடு உள்ளிடவும்.'
                : 'ஆசானின் அருள் வரிசையில் அடியாரின் தற்போதைய நிலை.',
            child: activeUser == null
                ? _buildLoginForm()
                : _buildProfile(activeUser),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const ValueKey('profile_phone'),
            controller: _profilePhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'பதிவு செய்த அலைபேசி எண்',
              prefixIcon: Icon(Icons.phone_android, color: Color(0xFF800000)),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'அலைபேசி எண்ணை உள்ளிடவும்'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('profile_queue'),
            controller: _profileQueueController,
            decoration: const InputDecoration(
              labelText: 'அருள் எண் அல்லது ஞான குறியீடு',
              prefixIcon: Icon(Icons.vpn_key, color: Color(0xFF800000)),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'விவரங்களை உள்ளிடவும்'
                : null,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => _openProfile(),
            child: const Text('சுயவிவரத்தைத் திறக்கவும்'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserRegistrationPage(store: widget.store),
                ),
              );
            },
            icon: const Icon(Icons.how_to_reg),
            label: const Text('புதிதாகப் பதிவு செய்க'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(RegistrationRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _InfoChip(label: 'அருள் எண்', value: record.queueNumber),
            _InfoChip(label: 'ஞான குறியீடு', value: record.memoryCode),
            _InfoChip(label: 'அடியார் பெயர்', value: record.name),
            _InfoChip(label: 'இணைப்புகள்', value: record.ticketCount.toString()),
            _InfoChip(label: 'சீடர்கள் எண்ணிக்கை', value: record.groupSize.toString()),
            _InfoChip(label: 'தற்போதைய ஞான நிலை', value: 'நிலை ${record.spiritualLevel} / 10'),
            _InfoChip(label: 'நிலைத் தன்மை', value: record.status),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF2E0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.auto_stories, color: Color(0xFF800000), size: 24),
              const SizedBox(height: 6),
              const Text(
                'தினசரி அருள்வாக்கு (Grace Word)',
                style: TextStyle(
                  color: Color(0xFF800000),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _getVerseForLevel(record.spiritualLevel),
                style: const TextStyle(
                  color: Color(0xFF4A0E17),
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'சீடர்களின் அடையாள எண்கள் (Disciples ID List)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF800000)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: record.entryIds
              .map<Widget>(
                (entryId) => Chip(
                  label: Text(entryId),
                  backgroundColor: const Color(0xFFFAF2E0),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _profileSubscription?.cancel();
            _activeUser = null;
            _profilePhoneController.clear();
            _profileQueueController.clear();
          }),
          icon: const Icon(Icons.logout),
          label: const Text('வெளியேறு'),
        ),
      ],
    );
  }

  void _openProfile() {
    final isValid = _loginFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final match = widget.store.findRegistrationByLogin(
      _profilePhoneController.text,
      _profileQueueController.text,
    );

    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('இத்தகவல்களில் அடியார் பதிவு எதுவும் இல்லை.')),
      );
      return;
    }

    setState(() {
      _activeUser = match;
    });
    _startLiveProfileListener();
  }
}

class TempleMemberPage extends StatefulWidget {
  const TempleMemberPage({super.key, required this.store});

  final TempleQueueStore store;

  @override
  State<TempleMemberPage> createState() => _TempleMemberPageState();
}

class _TempleMemberPageState extends State<TempleMemberPage> {
  final _loginFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  TempleMember? _loggedInMember;
  StreamSubscription? _registrationsSubscription;

  @override
  void initState() {
    super.initState();
    _loadPersistedLogin();
    _startRegistrationsListener();
  }

  Future<void> _loadPersistedLogin() async {
    final member = await widget.store.getPersistedLogin();
    if (member != null) {
      if (mounted) {
        setState(() {
          _loggedInMember = member;
        });
      }
      widget.store.startNotificationListener(member, (notification) {
        if (mounted) {
          setState(() {});
        }
      });
      PlatformNotificationHelper.requestPermission().then((granted) {
        debugPrint('App launch notification permission status: $granted');
      });
    }
  }

  void _startRegistrationsListener() {
    if (!widget.store.isFirebaseEnabled) return;
    try {
      _registrationsSubscription = widget.store.registrationsCollectionStream.listen((snapshot) {
        final loadedRegistrations = snapshot.docs
            .map((doc) => widget.store.registrationFromMapWrapper(doc.data()))
            .toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

        widget.store.registrations
          ..clear()
          ..addAll(loadedRegistrations);

        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      debugPrint('Error listening to registrations: $e');
    }
  }

  @override
  void dispose() {
    _registrationsSubscription?.cancel();
    widget.store.stopNotificationListener();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loggedInMember = _loggedInMember;
    final admittedCount = widget.store.registrations
        .where((record) => record.status == 'Admitted' || record.status.contains('அனுமதிக்கப்பட்டவர்'))
        .length;
    final waitingCount = widget.store.registrations
        .where((record) => record.status.contains('காத்திருக்கிறது') || record.status == 'Waiting approval')
        .length;
    final rejectedCount = widget.store.registrations
        .where((record) => record.status == 'Rejected' || record.status.contains('நிராகரிக்கப்பட்டவர்'))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ஆசான்கள் பலகை'),
        backgroundColor: const Color(0xFF800000),
        foregroundColor: const Color(0xFFFFD700),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionCard(
            title: loggedInMember == null ? 'ஆசான் உள்நுழைவு' : 'ஆன்மீகப் பலகை (Dashboard)',
            subtitle: loggedInMember == null
                ? 'ஆசான் கணக்கை நிர்வகிக்க உங்கள் கடவுச்சொல்லை உள்ளிடவும்.'
                : 'வணக்கம், ${loggedInMember.name}. தங்களின் அருள் வரிசையில் உள்ள சாதகர்களின் விவரங்கள்.',
            child: loggedInMember == null
                ? _buildLoginForm()
                : _buildDashboard(
                    loggedInMember,
                    admittedCount,
                    waitingCount,
                    rejectedCount,
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'வரிசையில் உள்ள சாதகர்கள் (Seekers in Lineage)',
            subtitle:
                'ஆசான்கள் தங்கள் சீடர்களின் நிலைகளை இங்கிருந்து கண்காணிக்கலாம்.',
            child: widget.store.registrations.isEmpty
                ? const _EmptyState(
                    title: 'இன்னும் பதிவுகள் இல்லை',
                    message:
                        'புதிய சாதகர்கள் இணையும் போது இங்கே காட்டப்படும்.',
                    icon: Icons.people_outline,
                  )
                : Column(
                    children: widget.store.registrations
                        .map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RegistrationTile(
                              record: record,
                              onMarkEntered: () =>
                                  _updateStatus(record, 'அனுமதிக்கப்பட்டவர்'),
                              onReject: () => _updateStatus(record, 'நிராகரிக்கப்பட்டவர்'),
                              onElevate: () => _elevateDisciple(record),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: loggedInMember == null
                ? 'நிர்வாக அறிவிப்புகள்'
                : '${loggedInMember.name} - அறிவிப்பு அலர்ட்',
            subtitle:
                'புதிய சாதகர்கள் இணையும் போது இங்கே உடனுக்குடன் அறிவிக்கப்படும்.',
            child: widget.store.notifications.isEmpty
                ? const _EmptyState(
                    title: 'அறிவிப்புகள் எதுவும் இல்லை',
                    message:
                        'சாதகர் பதிவு அலர்ட்கள் இங்கே தோன்றும்.',
                    icon: Icons.notifications_none,
                  )
                : Column(
                    children: widget.store.notifications
                        .where(
                          (notification) =>
                              loggedInMember == null ||
                              notification.memberName == loggedInMember.name ||
                              notification.memberName == 'Temple Office',
                        )
                        .map<Widget>(
                          (notification) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NotificationTile(
                              notification: notification,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const ValueKey('member_username'),
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'பயனர் பெயர் (Username)',
              prefixIcon: Icon(Icons.spa, color: Color(0xFF800000)),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'பயனர் பெயரை உள்ளிடவும்'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('member_password'),
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'ரகசியக் குறியீடு (Password)',
              prefixIcon: Icon(Icons.lock, color: Color(0xFF800000)),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'கடவுச்சொல்லை உள்ளிடவும்'
                : null,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => _login(),
            child: const Text('பலகையினுள் பிரவேசி'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(
    TempleMember member,
    int admittedCount,
    int waitingCount,
    int rejectedCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _InfoChip(label: 'ஆசான்', value: member.name),
            _InfoChip(
              label: 'அலர்ட்கள்',
              value: widget.store.notifications
                  .where((item) => item.memberName == member.name)
                  .length
                  .toString(),
            ),
            _InfoChip(label: 'அனுமதிக்கப்பட்டோர்', value: admittedCount.toString()),
          ],
        ),
        const SizedBox(height: 20),
        _DashboardChart(
          admitted: admittedCount,
          waiting: waitingCount,
          rejected: rejectedCount,
        ),
        const SizedBox(height: 20),
        _FastingDeclarationCard(
          store: widget.store,
          onUpdate: () => setState(() {}),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () {
            widget.store.clearPersistedLogin();
            widget.store.stopNotificationListener();
            setState(() {
              _loggedInMember = null;
              _usernameController.clear();
              _passwordController.clear();
            });
          },
          icon: const Icon(Icons.logout),
          label: const Text('ஆசான் கணக்கிலிருந்து வெளியேறு'),
        ),
      ],
    );
  }

  Future<void> _updateStatus(RegistrationRecord record, String status) async {
    await widget.store.updateRegistrationStatus(record, status);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _elevateDisciple(RegistrationRecord record) async {
    await widget.store.elevateSpiritualLevel(record);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${record.name} அடியாரின் ஞான நிலை உயர்த்தப்பட்டது! தற்போதைய நிலை: ${record.spiritualLevel}'),
          backgroundColor: const Color(0xFF800000),
        ),
      );
    }
  }

  void _login() {
    final isValid = _loginFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final member = widget.store.authenticateMember(
      _usernameController.text,
      _passwordController.text,
    );

    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('பயனர் பெயர் அல்லது கடவுச்சொல் தவறானது.')),
      );
      return;
    }

    widget.store.persistLogin(member);

    setState(() {
      _loggedInMember = member;
    });

    widget.store.startNotificationListener(member, (notification) {
      if (mounted) {
        setState(() {});
      }
    });

    PlatformNotificationHelper.requestPermission().then((granted) {
      debugPrint('Notification permission status: $granted');
    });
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.title,
    required this.subtitle,
    required this.totalRegistrations,
    required this.totalNotifications,
    required this.nextQueueNumber,
  });

  final String title;
  final String subtitle;
  final int totalRegistrations;
  final int totalNotifications;
  final String nextQueueNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A0E17), Color(0xFF800000), Color(0xFFD4AF37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF800000).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: const Color(0xFFFFD700),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MiniStat(
                label: 'மொத்த அடியார்கள்',
                value: totalRegistrations.toString(),
                icon: Icons.grain,
              ),
              _MiniStat(
                label: 'அறிவிப்புகள்',
                value: totalNotifications.toString(),
                icon: Icons.notifications_active,
              ),
              _MiniStat(
                label: 'அடுத்த அருள் எண்',
                value: nextQueueNumber,
                icon: Icons.tag,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardChart extends StatelessWidget {
  const _DashboardChart({
    required this.admitted,
    required this.waiting,
    required this.rejected,
  });

  final int admitted;
  final int waiting;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    final total = admitted + waiting + rejected;
    final admittedValue = total == 0 ? 0.0 : admitted / total;
    final waitingValue = total == 0 ? 0.0 : waiting / total;
    final rejectedValue = total == 0 ? 0.0 : rejected / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF2E0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4AF37)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'அருள் நிலைகளின் பகுப்பாய்வு',
            style: TextStyle(
              color: Color(0xFF800000),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          _ChartRow(
            label: 'அனுமதித்தவை',
            value: admitted,
            ratio: admittedValue,
            color: const Color(0xFF800000),
          ),
          const SizedBox(height: 10),
          _ChartRow(
            label: 'காத்திருப்பவை',
            value: waiting,
            ratio: waitingValue,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 10),
          _ChartRow(
            label: 'நிராகரித்தவை',
            value: rejected,
            ratio: rejectedValue,
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}

class _ChartRow extends StatelessWidget {
  const _ChartRow({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  final String label;
  final int value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 24,
          child: Text(value.toString(), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF2E0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF800000).withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF800000)),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B584E)),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFDF0),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6C280)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD4AF37)),
                ),
                child: Icon(icon, color: const Color(0xFF800000)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF800000),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(message, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF800000)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6C280)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: const Color(0xFF800000), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF4A0E17)),
          ),
        ],
      ),
    );
  }
}

class _StepperCard extends StatelessWidget {
  const _StepperCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.onAdd,
    required this.onRemove,
    required this.addKey,
    required this.removeKey,
  });

  final String label;
  final String value;
  final String hint;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final Key addKey;
  final Key removeKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6C280)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF800000), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B584E),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: removeKey,
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF800000)),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF800000)),
          ),
          IconButton(
            key: addKey,
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF800000)),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final TempleNotification notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6C280)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF800000),
                  ),
                ),
              ),
              Text(
                notification.memberName,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF800000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(notification.message),
          const SizedBox(height: 8),
          Text(
            _formatTime(notification.createdAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B584E)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} $hour:$minute';
  }
}

class _RegistrationTile extends StatelessWidget {
  const _RegistrationTile({
    required this.record,
    required this.onMarkEntered,
    required this.onReject,
    required this.onElevate,
  });

  final RegistrationRecord record;
  final VoidCallback onMarkEntered;
  final VoidCallback onReject;
  final VoidCallback onElevate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6C280)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF800000),
                  ),
                ),
              ),
              Chip(
                label: Text(record.status),
                backgroundColor: const Color(0xFFFAF2E0),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'அருள் எண்: ${record.queueNumber}  |  அலைபேசி: ${record.phone}  |  ஞான குறியீடு: ${record.memoryCode}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B584E)),
          ),
          const SizedBox(height: 8),
          Text(
            'தற்போதைய தியான ஞான நிலை: நிலை ${record.spiritualLevel} / 10',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF800000)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipLabel(label: 'குருநாதர்', value: record.referenceMember),
              _ChipLabel(label: 'இணைப்பு', value: record.ticketCount.toString()),
              _ChipLabel(label: 'சீடர்கள்', value: record.groupSize.toString()),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: record.entryIds
                .map((entryId) => Chip(
                      label: Text(entryId),
                      backgroundColor: const Color(0xFFFAF2E0),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: onMarkEntered,
                icon: const Icon(Icons.check_circle, color: Color(0xFF800000)),
                label: const Text('அனுமதி (Admit)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFAF2E0),
                  foregroundColor: const Color(0xFF800000),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.block),
                label: const Text('நிராகரி (Reject)'),
              ),
              if (record.spiritualLevel < 10)
                FilledButton.icon(
                  onPressed: onElevate,
                  icon: const Icon(Icons.trending_up, color: Color(0xFFFFD700)),
                  label: const Text('ஞான நிலை உயர்த்து'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: const Color(0xFFFAF2E0),
      label: Text('$label: $value'),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6C280)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: const Color(0xFF800000)),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF800000)),
          ),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _FastingCountdownWidget extends StatefulWidget {
  const _FastingCountdownWidget({
    required this.title,
    required this.targetTime,
  });

  final String title;
  final DateTime targetTime;

  @override
  State<_FastingCountdownWidget> createState() => _FastingCountdownWidgetState();
}

class _FastingCountdownWidgetState extends State<_FastingCountdownWidget> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTimeLeft();
        });
      }
    });
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    if (widget.targetTime.isAfter(now)) {
      _timeLeft = widget.targetTime.difference(now);
    } else {
      _timeLeft = Duration.zero;
      _timer.cancel();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == Duration.zero) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF800000), // Deep Maroon
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.alarm_on, color: Color(0xFFFFD700), size: 28),
            const SizedBox(height: 8),
            Text(
              '${widget.title} விரதம் ஆரம்பமாகிவிட்டது / நிறைவடைந்துவிட்டது!',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF2E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFF800000), size: 28),
          const SizedBox(height: 6),
          Text(
            'விரத அறிவிப்பு: ${widget.title}',
            style: const TextStyle(
              color: Color(0xFF800000),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$hours:$minutes:$seconds',
            style: const TextStyle(
              color: Color(0xFF800000),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'விரதம் தொடங்க இன்னும் மீதமுள்ள நேரம்',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FastingDeclarationCard extends StatefulWidget {
  const _FastingDeclarationCard({required this.store, required this.onUpdate});

  final TempleQueueStore store;
  final VoidCallback onUpdate;

  @override
  State<_FastingDeclarationCard> createState() => _FastingDeclarationCardState();
}

class _FastingDeclarationCardState extends State<_FastingDeclarationCard> {
  final _titleController = TextEditingController();
  DateTime? _selectedTime;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: Color(0xFFE6C280)),
        const SizedBox(height: 10),
        const Text(
          'விரத அறிவிப்புப் பலகை (Fasting Declaration)',
          style: TextStyle(
            color: Color(0xFF800000),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'விரதப் பெயர் (எ.கா: பிரதோஷ விரதம்)',
            prefixIcon: Icon(Icons.edit_calendar_outlined, color: Color(0xFF800000)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                _selectedTime == null
                    ? 'விரத நேரம் தேர்வு செய்யப்படவில்லை'
                    : 'தேர்ந்தெடுக்கப்பட்ட நேரம்:\n${_formatDateTime(_selectedTime!)}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.date_range, color: Color(0xFF800000)),
              label: const Text('நேரம் தேர்ந்தெடு'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFAF2E0),
                foregroundColor: const Color(0xFF800000),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _declareFasting,
          icon: const Icon(Icons.campaign),
          label: const Text('அனைத்து அடியாருக்கும் விரதம் அறிவிக்கவும்'),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $hour:$min';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _declareFasting() async {
    if (_titleController.text.trim().isEmpty || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('விவரங்களை முழுமையாக நிரப்பவும்.')),
      );
      return;
    }

    await widget.store.updateFastingEvent(
      _titleController.text.trim(),
      _selectedTime!,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('விரத அறிவிப்பு வெளியிடப்பட்டது!'),
        backgroundColor: Color(0xFF800000),
      ),
    );
    
    _titleController.clear();
    setState(() {
      _selectedTime = null;
    });
    widget.onUpdate();
  }
}

extension FirstWhereOrNullExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
