import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../config/workplace_config.dart';
import '../services/attendance_service.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _attendanceService = AttendanceService();
  final _locationService = LocationService();
  final _localAuth = LocalAuthentication();
  bool _isRegistering = false;

  User get _user => FirebaseAuth.instance.currentUser!;

  Future<bool> _confirmBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canAuthenticate =
          supported && await _localAuth.canCheckBiometrics;
      final biometrics = canAuthenticate
          ? await _localAuth.getAvailableBiometrics()
          : <BiometricType>[];
      if (biometrics.isEmpty) {
        _showMessage(
          'Este aparelho não possui biometria configurada. '
          'Configure-a ou use um aparelho compatível.',
        );
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Confirme sua identidade para registrar o ponto.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (error) {
      _showMessage('Não foi possível validar a biometria: ${error.code.name}.');
      return false;
    }
  }

  Future<void> _registerAttendance() async {
    if (_isRegistering) return;
    setState(() => _isRegistering = true);

    try {
      final authenticated = await _confirmBiometrics();
      if (!authenticated || !mounted) return;

      final location = await _locationService.getAttendanceLocation();
      if (!location.isWithinWorkplace) {
        _showMessage(
          'Você está a ${location.distanceMeters.round()} m do local. '
          'O limite para registrar é de 100 m.',
        );
        return;
      }

      await _attendanceService.createRecord(
        userId: _user.uid,
        email: _user.email ?? '',
        location: location,
      );
      if (mounted) {
        _showMessage(
          'Ponto registrado a ${location.distanceMeters.round()} m do local.',
        );
      }
    } on FirebaseException catch (error) {
      _showMessage('Erro ao salvar o registro: ${error.message ?? error.code}.');
    } on StateError catch (error) {
      _showMessage(error.message.toString());
    } catch (error) {
      _showMessage('Não foi possível registrar o ponto: $error');
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (_user.displayName?.trim().isNotEmpty ?? false)
        ? _user.displayName!.trim().split(' ').first
        : (_user.email ?? 'Funcionário').split('@').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SENAI Ponto',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Olá, $firstName!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF102A43),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Registre sua jornada com segurança.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF52606D),
                ),
          ),
          const SizedBox(height: 24),
          _LocationCard(),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: const Color(0xFF102A43),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.fingerprint_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Registrar ponto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Confirme sua biometria. O registro só será salvo '
                    'se você estiver a até 100 m do local de trabalho.',
                    style: TextStyle(color: Color(0xFFD9E2EC), height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _isRegistering ? null : _registerAttendance,
                      icon: _isRegistering
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.fingerprint_rounded),
                      label: Text(
                        _isRegistering ? 'Verificando...' : 'Bater ponto',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC857),
                        foregroundColor: const Color(0xFF102A43),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Registros recentes',
                  style: TextStyle(
                    color: Color(0xFF102A43),
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.sync_rounded,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 4),
              const Text('ao vivo'),
            ],
          ),
          const SizedBox(height: 10),
          _AttendanceHistory(
            stream: _attendanceService.watchRecentRecords(_user.uid),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final configured = WorkplaceConfig.isConfigured;
    return Card(
      elevation: 0,
      color: configured
          ? const Color(0xFFE7F6F4)
          : const Color(0xFFFFF4D6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              configured ? Icons.location_on_rounded : Icons.info_outline,
              color: configured
                  ? const Color(0xFF087E8B)
                  : const Color(0xFF9A6700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    WorkplaceConfig.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    configured
                        ? 'Raio permitido: 100 m'
                        : 'Configure as coordenadas do local no projeto.',
                    style: const TextStyle(color: Color(0xFF52606D)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceHistory extends StatelessWidget {
  const _AttendanceHistory({required this.stream});

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _HistoryMessage(
            icon: Icons.cloud_off_rounded,
            text: 'Não foi possível carregar o histórico.',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final records = snapshot.data?.docs ?? [];
        if (records.isEmpty) {
          return const _HistoryMessage(
            icon: Icons.event_note_rounded,
            text: 'Seus registros aparecerão aqui.',
          );
        }

        return Column(
          children: [
            for (final record in records)
              _AttendanceTile(data: record.data()),
          ],
        );
      },
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final timestamp = data['timestamp'];
    final date = timestamp is Timestamp ? timestamp.toDate() : null;
    final distance = (data['distanceMeters'] as num?)?.round();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE7F6F4),
          child: Icon(Icons.check_rounded, color: Color(0xFF087E8B)),
        ),
        title: const Text(
          'Ponto registrado',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          date == null
              ? 'Sincronizando horário...'
              : '${_formatDate(date)} • ${distance ?? '--'} m do local',
        ),
        trailing: const Icon(Icons.verified_user_outlined, size: 20),
      ),
    );
  }

  String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF627D98)),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
