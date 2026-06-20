import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';

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

  ThemeData _buildTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F766E),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F7FB),
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: const Color(0xFF153047),
        displayColor: const Color(0xFF153047),
        fontFamily: 'Georgia',
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
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Temple Reference Queue',
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
  }) : status = 'Waiting approval';

  final String queueNumber;
  final String memoryCode;
  final String name;
  final String phone;
  final String referenceMember;
  final int ticketCount;
  final int groupSize;
  final List<String> entryIds;
  final DateTime createdAt;
  String status;
}

class TempleQueueStore {
  static const String templeOfficeSmsPhone = String.fromEnvironment(
    'TEMPLE_OFFICE_SMS_PHONE',
  );

  static const List<TempleMember> members = [
    TempleMember(
      name: 'Arun',
      username: 'arun',
      password: 'arun@111',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_ARUN_PHONE'),
    ),
    TempleMember(
      name: 'Bala',
      username: 'bala',
      password: 'bala@112',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_BALA_PHONE'),
    ),
    TempleMember(
      name: 'Chandra',
      username: 'chandra',
      password: 'chandra@113',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_CHANDRA_PHONE'),
    ),
    TempleMember(
      name: 'Deepa',
      username: 'deepa',
      password: 'deepa@114',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_DEEPA_PHONE'),
    ),
    TempleMember(
      name: 'Eshwar',
      username: 'eshwar',
      password: 'eshwar@115',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_ESHWAR_PHONE'),
    ),
    TempleMember(
      name: 'Farah',
      username: 'farah',
      password: 'farah@116',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_FARAH_PHONE'),
    ),
    TempleMember(
      name: 'Gopi',
      username: 'gopi',
      password: 'gopi@117',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_GOPI_PHONE'),
    ),
    TempleMember(
      name: 'Hema',
      username: 'hema',
      password: 'hema@118',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_HEMA_PHONE'),
    ),
    TempleMember(
      name: 'Ibrahim',
      username: 'ibrahim',
      password: 'ibrahim@119',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_IBRAHIM_PHONE'),
    ),
    TempleMember(
      name: 'Jaya',
      username: 'jaya',
      password: 'jaya@120',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_JAYA_PHONE'),
    ),
    TempleMember(
      name: 'Kiran',
      username: 'kiran',
      password: 'kiran@121',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_KIRAN_PHONE'),
    ),
    TempleMember(
      name: 'Lakshmi',
      username: 'lakshmi',
      password: 'lakshmi@122',
      smsPhone: String.fromEnvironment('TEMPLE_MEMBER_LAKSHMI_PHONE'),
    ),
  ];

  final List<RegistrationRecord> registrations = [];
  final List<TempleNotification> notifications = [];
  final TextbeeSmsService _smsService = TextbeeSmsService();
  final Random _random = Random.secure();
  int nextQueueNumber = 1;
  bool _firebaseEnabled = false;

  bool get isFirebaseEnabled => _firebaseEnabled;

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
  }

  Future<RegistrationRecord> registerVisitor({
    required String name,
    required String phone,
    required String referenceMember,
    required int ticketCount,
  }) async {
    final queueNumber = 'Q-${nextQueueNumber.toString().padLeft(3, '0')}';
    final memoryCode = _generateMemoryCode();
    final groupSize = ticketCount * 2;
    final entryIds = List<String>.generate(
      groupSize,
      (index) => '$queueNumber-${(index + 1).toString().padLeft(2, '0')}',
    );

    final registration = RegistrationRecord(
      queueNumber: queueNumber,
      memoryCode: memoryCode,
      name: name,
      phone: phone,
      referenceMember: referenceMember,
      ticketCount: ticketCount,
      groupSize: groupSize,
      entryIds: entryIds,
      createdAt: DateTime.now(),
    );

    registrations.insert(0, registration);
    final userNotification = TempleNotification(
      title: 'New visitor registered',
      message:
          '$name booked $ticketCount ticket(s) for $groupSize member(s). Queue $queueNumber and memory code $memoryCode are waiting for entry.',
      memberName: referenceMember,
      createdAt: registration.createdAt,
    );
    final officeNotification = TempleNotification(
      title: 'Temple office alert',
      message:
          '$name completed registration with queue $queueNumber and memory code $memoryCode.',
      memberName: 'Temple Office',
      createdAt: registration.createdAt,
    );

    notifications.insert(0, officeNotification);
    notifications.insert(0, userNotification);
    nextQueueNumber++;
    await _saveRegistration(registration);
    await _saveNotification(userNotification);
    await _saveNotification(officeNotification);
    await _saveQueueState();
    return registration;
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

    await _registrationsCollection.doc(record.queueNumber).update(
      <String, dynamic>{'status': status},
    );
  }

  Future<void> _loadFromFirebase() async {
    if (!_firebaseEnabled) {
      return;
    }

    final stateSnapshot = await _stateDocument.get();
    if (stateSnapshot.exists) {
      final data = stateSnapshot.data();
      nextQueueNumber = (data?['nextQueueNumber'] as int?) ?? 1;
    }

    final registrationsSnapshot = await _registrationsCollection.get();
    final loadedRegistrations =
        registrationsSnapshot.docs
            .map((doc) => _registrationFromMap(doc.data()))
            .toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    final notificationsSnapshot = await _notificationsCollection.get();
    final loadedNotifications =
        notificationsSnapshot.docs
            .map((doc) => _notificationFromMap(doc.data()))
            .toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    registrations
      ..clear()
      ..addAll(loadedRegistrations);
    notifications
      ..clear()
      ..addAll(loadedNotifications);
  }

  Future<void> _saveRegistration(RegistrationRecord registration) async {
    if (!_firebaseEnabled) {
      return;
    }

    await _registrationsCollection
        .doc(registration.queueNumber)
        .set(_registrationToMap(registration));
  }

  Future<void> _seedTempleMembers() async {
    if (!_firebaseEnabled) {
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    final createdAt = DateTime.now().toIso8601String();
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
    await batch.commit();
  }

  Future<void> _saveNotification(TempleNotification notification) async {
    if (!_firebaseEnabled) {
      return;
    }

    await _notificationsCollection.add(_notificationToMap(notification));
  }

  Future<void> _saveQueueState() async {
    if (!_firebaseEnabled) {
      return;
    }

    await _stateDocument.set(<String, dynamic>{
      'nextQueueNumber': nextQueueNumber,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
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
      'createdAt': record.createdAt.toIso8601String(),
      'status': record.status,
      'type': 'Visitor',
    };
  }

  Map<String, dynamic> _notificationToMap(TempleNotification notification) {
    return <String, dynamic>{
      'title': notification.title,
      'message': notification.message,
      'memberName': notification.memberName,
      'createdAt': notification.createdAt.toIso8601String(),
    };
  }

  RegistrationRecord _registrationFromMap(Map<String, dynamic> data) {
    return RegistrationRecord(
      queueNumber: data['queueNumber'] as String,
      memoryCode: (data['memoryCode'] as String?) ?? _generateMemoryCode(),
      name: data['name'] as String,
      phone: data['phone'] as String,
      referenceMember: data['referenceMember'] as String,
      ticketCount: (data['ticketCount'] as num).toInt(),
      groupSize: (data['groupSize'] as num).toInt(),
      entryIds: (data['entryIds'] as List<dynamic>)
          .map((value) => value.toString())
          .toList(),
      createdAt: DateTime.parse(data['createdAt'] as String),
    )..status = (data['status'] as String?) ?? 'Waiting approval';
  }

  TempleNotification _notificationFromMap(Map<String, dynamic> data) {
    return TempleNotification(
      title: data['title'] as String,
      message: data['message'] as String,
      memberName: data['memberName'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
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
            colors: [Color(0xFFF4F7FB), Color(0xFFE4F1EE), Color(0xFFFDF7ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _HeroBanner(
                    title: 'Temple Reference Queue',
                    subtitle:
                        'Use separate pages for visitor registration, user profile access, and temple member login.',
                    totalRegistrations: store.registrations.length,
                    totalNotifications: store.notifications.length,
                    nextQueueNumber:
                        'Q-${store.nextQueueNumber.toString().padLeft(3, '0')}',
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Choose a page',
                    subtitle: 'Each audience has its own screen and flow.',
                    child: Column(
                      children: [
                        _NavigationTile(
                          key: const ValueKey('nav_user_registration'),
                          title: 'User Registration',
                          message: 'Open the visitor registration page.',
                          icon: Icons.how_to_reg_outlined,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    UserRegistrationPage(store: store),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _NavigationTile(
                          key: const ValueKey('nav_user_profile'),
                          title: 'User Profile',
                          message: 'Open your saved queue and profile page.',
                          icon: Icons.person_outline,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UserProfilePage(store: store),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _NavigationTile(
                          key: const ValueKey('nav_temple_members'),
                          title: 'Temple Members',
                          message:
                              'Login with username and password to manage registrations.',
                          icon: Icons.badge_outlined,
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
      appBar: AppBar(title: const Text('User Registration')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionCard(
            title: 'Register visitor',
            subtitle:
                'Create a queue number before opening the user profile page.',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const ValueKey('registration_name'),
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter the visitor name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const ValueKey('registration_phone'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 8
                        ? 'Enter a valid phone number'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('registration_reference'),
                    initialValue: _selectedReferenceMember,
                    decoration: const InputDecoration(
                      labelText: 'Reference member',
                      prefixIcon: Icon(Icons.group_outlined),
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
                    label: 'Tickets',
                    value: _ticketCount.toString(),
                    hint: '1 ticket = 2 users',
                    onAdd: () => setState(() => _ticketCount++),
                    onRemove: _ticketCount > 1
                        ? () => setState(() => _ticketCount--)
                        : null,
                    addKey: const ValueKey('ticket_add'),
                    removeKey: const ValueKey('ticket_remove'),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    key: const ValueKey('register_submit'),
                    onPressed: () => _submitRegistration(),
                    icon: const Icon(Icons.badge_outlined),
                    label: const Text('Generate queue ID'),
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
        content: Text(
          'Queue ${registration.queueNumber} generated for ${registration.name}',
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

  @override
  void initState() {
    super.initState();
    _activeUser = widget.initialRegistration;
    if (_activeUser != null) {
      _profilePhoneController.text = _activeUser!.phone;
      _profileQueueController.text = _activeUser!.queueNumber;
    }
  }

  @override
  void dispose() {
    _profilePhoneController.dispose();
    _profileQueueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = _activeUser;
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionCard(
            title: activeUser == null
                ? 'Open your profile'
                : 'Your temple pass',
            subtitle: activeUser == null
                ? 'Use the phone number with your queue number or memory code.'
                : 'Your ticket set is ready. Show the queue number or memory code at the gate.',
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
              labelText: 'Registered phone number',
              prefixIcon: Icon(Icons.phone_android_outlined),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter the phone number'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('profile_queue'),
            controller: _profileQueueController,
            decoration: const InputDecoration(
              labelText: 'Queue number or memory code',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter the queue number or memory code'
                : null,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => _openProfile(),
            child: const Text('Open my profile'),
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
            icon: const Icon(Icons.how_to_reg_outlined),
            label: const Text('Go to registration'),
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
            _InfoChip(label: 'Queue number', value: record.queueNumber),
            _InfoChip(label: 'Memory code', value: record.memoryCode),
            _InfoChip(label: 'Name', value: record.name),
            _InfoChip(label: 'Tickets', value: record.ticketCount.toString()),
            _InfoChip(label: 'Members', value: record.groupSize.toString()),
            _InfoChip(label: 'Status', value: record.status),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Entry IDs for the whole group',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: record.entryIds
              .map<Widget>(
                (entryId) => Chip(
                  label: Text(entryId),
                  backgroundColor: const Color(0xFFEAF4F2),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _activeUser = null;
            _profilePhoneController.clear();
            _profileQueueController.clear();
          }),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
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
        const SnackBar(content: Text('No matching registration found.')),
      );
      return;
    }

    setState(() {
      _activeUser = match;
    });
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loggedInMember = _loggedInMember;
    final admittedCount = widget.store.registrations
        .where((record) => record.status == 'Admitted')
        .length;
    final waitingCount = widget.store.registrations
        .where((record) => record.status == 'Waiting approval')
        .length;
    final rejectedCount = widget.store.registrations
        .where((record) => record.status == 'Rejected')
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Temple Members')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionCard(
            title: loggedInMember == null ? 'Member login' : 'Member dashboard',
            subtitle: loggedInMember == null
                ? 'Log in with your username and password to manage registrations.'
                : 'Signed in as ${loggedInMember.name}.',
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
            title: 'Registered users',
            subtitle:
                'Temple staff can review every registered visitor and their queue status.',
            child: widget.store.registrations.isEmpty
                ? const _EmptyState(
                    title: 'No registered users yet',
                    message:
                        'New registrations will appear here automatically.',
                    icon: Icons.people_alt_outlined,
                  )
                : Column(
                    children: widget.store.registrations
                        .map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RegistrationTile(
                              record: record,
                              onMarkEntered: () =>
                                  _updateStatus(record, 'Admitted'),
                              onReject: () => _updateStatus(record, 'Rejected'),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: loggedInMember == null
                ? 'Temple inbox'
                : '${loggedInMember.name} notifications',
            subtitle:
                'Each registration sends a notification to the selected reference member.',
            child: widget.store.notifications.isEmpty
                ? const _EmptyState(
                    title: 'No notifications yet',
                    message:
                        'As soon as visitors register, alerts will appear here.',
                    icon: Icons.notifications_none_outlined,
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
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter the username'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('member_password'),
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter the password'
                : null,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => _login(),
            child: const Text('Login to temple dashboard'),
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
            _InfoChip(label: 'Member', value: member.name),
            _InfoChip(
              label: 'Alerts',
              value: widget.store.notifications
                  .where((item) => item.memberName == member.name)
                  .length
                  .toString(),
            ),
            _InfoChip(label: 'Admitted', value: admittedCount.toString()),
          ],
        ),
        const SizedBox(height: 16),
        _DashboardChart(
          admitted: admittedCount,
          waiting: waitingCount,
          rejected: rejectedCount,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _loggedInMember = null;
            _usernameController.clear();
            _passwordController.clear();
          }),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
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
        const SnackBar(content: Text('Invalid username or password.')),
      );
      return;
    }

    setState(() {
      _loggedInMember = member;
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF164E63), Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF164E63).withValues(alpha: 0.24),
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
              color: Colors.white,
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
                label: 'Registrations',
                value: totalRegistrations.toString(),
                icon: Icons.event_note_outlined,
              ),
              _MiniStat(
                label: 'Notifications',
                value: totalNotifications.toString(),
                icon: Icons.notifications_outlined,
              ),
              _MiniStat(
                label: 'Next queue',
                value: nextQueueNumber,
                icon: Icons.numbers_outlined,
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
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
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
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Queue status chart',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _ChartRow(
            label: 'Admitted',
            value: admitted,
            ratio: admittedValue,
            color: const Color(0xFF0F766E),
          ),
          const SizedBox(height: 10),
          _ChartRow(
            label: 'Waiting',
            value: waiting,
            ratio: waitingValue,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 10),
          _ChartRow(
            label: 'Rejected',
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
        SizedBox(width: 84, child: Text(label)),
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
          child: Text(value.toString(), textAlign: TextAlign.end),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF153047).withValues(alpha: 0.08),
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
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF587086)),
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
      color: const Color(0xFFF8FBFD),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF0F766E)),
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(message),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
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
        color: const Color(0xFFF4FBFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: const Color(0xFF5E7483)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: removeKey,
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          IconButton(
            key: addKey,
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
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
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  ),
                ),
              ),
              Text(
                notification.memberName,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF0F766E),
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
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
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
  });

  final RegistrationRecord record;
  final VoidCallback onMarkEntered;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EEF3)),
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
                  ),
                ),
              ),
              Chip(label: Text(record.status)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${record.queueNumber} - ${record.phone} - Memory ${record.memoryCode}',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipLabel(label: 'Reference', value: record.referenceMember),
              _ChipLabel(label: 'Memory code', value: record.memoryCode),
              _ChipLabel(
                label: 'Tickets',
                value: record.ticketCount.toString(),
              ),
              _ChipLabel(label: 'Members', value: record.groupSize.toString()),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: record.entryIds
                .map((entryId) => Chip(label: Text(entryId)))
                .toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: onMarkEntered,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark entered'),
              ),
              OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.block_outlined),
                label: const Text('Reject'),
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
      backgroundColor: const Color(0xFFF4FBFA),
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
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: const Color(0xFF0F766E)),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
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
