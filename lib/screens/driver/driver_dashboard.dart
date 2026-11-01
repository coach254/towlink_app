import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  static const String baseUrl = 'http://10.0.2.2:8765';

  final TextEditingController _driverIdController = TextEditingController();

  Map<String, dynamic>? _driver;
  List<dynamic> _availableJobs = [];
  List<dynamic> _activeJobs = [];
  List<dynamic> _historyJobs = [];
  bool _loading = false;
  String? _message;
  bool _showIdField = true;

  @override
  void dispose() {
    _driverIdController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    final id = int.tryParse(_driverIdController.text.trim());
    if (id == null || id < 1) {
      setState(() => _message = 'Enter a valid driver ID.');
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final driverResponse = await http
          .get(Uri.parse('$baseUrl/drivers/$id'))
          .timeout(const Duration(seconds: 15));

      if (driverResponse.statusCode != 200) {
        throw Exception('Could not load driver details.');
      }

      final driver = jsonDecode(driverResponse.body) as Map<String, dynamic>;

      List<dynamic> available = [];
      List<dynamic> active = [];
      List<dynamic> history = [];

      if (driver['approval_status'] == 'approved') {
        // Available jobs (requested, no driver assigned)
        final availResponse = await http
            .get(Uri.parse('$baseUrl/tow-requests/available'))
            .timeout(const Duration(seconds: 15));
        if (availResponse.statusCode == 200) {
          available = jsonDecode(availResponse.body) as List<dynamic>;
        }

        // Driver's own jobs — split into active and history
        final jobsResponse = await http
            .get(Uri.parse('$baseUrl/drivers/$id/jobs'))
            .timeout(const Duration(seconds: 15));
        if (jobsResponse.statusCode == 200) {
          final jobs = jsonDecode(jobsResponse.body) as List<dynamic>;
          for (final job in jobs) {
            final status = job['status'] as String?;
            if (status == 'completed') {
              history.add(job);
            } else {
              active.add(job);
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _driver = driver;
        _availableJobs = available;
        _activeJobs = active;
        _historyJobs = history;
        _showIdField = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _message =
            'Could not load dashboard. Check that the backend is running.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setAvailability(bool available) async {
    final id = _driver?['id'];
    if (id == null) return;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/drivers/$id/availability'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_available': available}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _driver = jsonDecode(response.body) as Map<String, dynamic>;
        });
        _showMessage(
          available ? 'You are now online.' : 'You are now offline.',
        );
        await _loadDashboard();
      } else {
        _showMessage('Could not change availability.');
      }
    } catch (_) {
      _showMessage('Could not connect to the backend.');
    }
  }

  Future<void> _acceptJob(int requestId) async {
    final driverId = _driver?['id'];
    if (driverId == null) return;

    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/tow-requests/$requestId/accept?driver_id=$driverId',
        ),
      );
      if (response.statusCode == 200) {
        _showMessage('Job accepted successfully.');
      } else {
        final body = jsonDecode(response.body);
        _showMessage(body['detail']?.toString() ?? 'Could not accept job.');
      }
    } catch (_) {
      _showMessage('Could not connect to the backend.');
    }
    await _loadDashboard();
  }

  Future<void> _advanceStatus(int requestId, String nextStatus) async {
    final driverId = _driver?['id'];
    if (driverId == null) return;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tow-requests/$requestId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': nextStatus, 'driver_id': driverId}),
      );

      if (response.statusCode == 200) {
        _showMessage(_statusActionLabel(nextStatus));
      } else {
        final body = jsonDecode(response.body);
        _showMessage(body['detail']?.toString() ?? 'Could not update status.');
      }
    } catch (_) {
      _showMessage('Could not connect to the backend.');
    }
    await _loadDashboard();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final approved = _driver?['approval_status'] == 'approved';
    final online = _driver?['is_available'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TowLink Driver'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_driver != null)
            IconButton(
              tooltip: 'Change driver',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () {
                setState(() {
                  _driver = null;
                  _availableJobs = [];
                  _activeJobs = [];
                  _historyJobs = [];
                  _showIdField = true;
                  _driverIdController.clear();
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const Icon(
                Icons.local_shipping,
                size: 58,
                color: Color(0xFF1565C0),
              ),
              const SizedBox(height: 12),
              const Text(
                'Driver Dashboard',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your registration and available towing jobs.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (_showIdField) ...[
                TextField(
                  controller: _driverIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Driver ID',
                    hintText: 'Enter your registered driver ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _loadDashboard,
                  icon: const Icon(Icons.refresh),
                  label: Text(_loading ? 'Loading...' : 'Load Dashboard'),
                ),
              ],

              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, style: const TextStyle(color: Colors.red)),
              ],

              if (_driver != null) ...[
                const SizedBox(height: 24),
                _driverCard(approved, online),
              ],

              if (approved && _driver != null) ...[
                const SizedBox(height: 28),
                _sectionTitle('Available towing jobs'),
                if (_availableJobs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('No available jobs at the moment.'),
                    ),
                  )
                else
                  ..._availableJobs.map(_availableJobCard),
                const SizedBox(height: 28),
                _sectionTitle('My active jobs'),
                if (_activeJobs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('No active jobs.'),
                    ),
                  )
                else
                  ..._activeJobs.map(_activeJobCard),
                const SizedBox(height: 28),
                _sectionTitle('History'),
                if (_historyJobs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('No completed jobs yet.'),
                    ),
                  )
                else
                  ..._historyJobs.map(_historyCard),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _driverCard(bool approved, bool online) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _driver!['full_name'].toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Phone: ${_driver!['phone']}'),
            Text('Vehicle: ${_driver!['vehicle_type']}'),
            Text('Registration: ${_driver!['vehicle_registration']}'),
            const SizedBox(height: 10),
            Text(
              'Approval: ${_driver!['approval_status']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: approved ? Colors.green : Colors.orange,
              ),
            ),
            if (approved) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available for jobs'),
                subtitle: Text(online ? 'You are online' : 'You are offline'),
                value: online,
                onChanged: _setAvailability,
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Your registration is awaiting approval.'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _availableJobCard(dynamic job) {
    final requestId = job['id'] as int;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request #$requestId',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text('Pickup: ${job['pickup_location']}'),
            Text('Destination: ${job['destination'] ?? 'Not specified'}'),
            Text('Vehicle: ${job['vehicle_type']}'),
            Text('Problem: ${job['problem_description']}'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _acceptJob(requestId),
                child: const Text('Accept Job'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeJobCard(dynamic job) {
    final requestId = job['id'] as int;
    final status = job['status'] as String? ?? 'accepted';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Request #$requestId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 10),
            Text('Customer: ${job['customer_name']}'),
            Text('Phone: ${job['phone']}'),
            Text('Pickup: ${job['pickup_location']}'),
            Text('Destination: ${job['destination'] ?? 'Not specified'}'),
            Text('Vehicle: ${job['vehicle_type']}'),
            Text('Problem: ${job['problem_description']}'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _advanceStatus(requestId, _nextStatus(status)),
                icon: Icon(_nextStatusIcon(status)),
                label: Text(_nextStatusButtonLabel(status)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyCard(dynamic job) {
    final requestId = job['id'] as int;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Request #$requestId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                const Chip(
                  label: Text('Completed'),
                  backgroundColor: Color(0xFFDDF5DF),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Customer: ${job['customer_name']}'),
            Text('Pickup: ${job['pickup_location']}'),
            Text('Destination: ${job['destination'] ?? 'Not specified'}'),
            if (job['completed_at'] != null) ...[
              const SizedBox(height: 6),
              Text(
                'Completed at: ${_formatTime(job['completed_at'])}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final labels = {
      'accepted': 'Accepted',
      'en_route': 'En route',
      'arrived': 'Arrived',
      'towing': 'Towing',
      'completed': 'Completed',
    };
    final colors = {
      'accepted': const Color(0xFFE3F0FF),
      'en_route': const Color(0xFFFFF3D6),
      'arrived': const Color(0xFFE9E3FF),
      'towing': const Color(0xFFFFE3E3),
      'completed': const Color(0xFFDDF5DF),
    };
    return Chip(
      label: Text(labels[status] ?? status),
      backgroundColor: colors[status] ?? const Color(0xFFEEEEEE),
    );
  }

  String _nextStatus(String current) {
    const map = {
      'accepted': 'en_route',
      'en_route': 'arrived',
      'arrived': 'towing',
      'towing': 'completed',
    };
    return map[current] ?? 'completed';
  }

  String _nextStatusButtonLabel(String current) {
    const map = {
      'accepted': "I'm on my way",
      'en_route': "I've arrived",
      'arrived': 'Start towing',
      'towing': 'Complete job',
    };
    return map[current] ?? 'Done';
  }

  String _statusActionLabel(String next) {
    const map = {
      'en_route': 'Marked as on the way.',
      'arrived': 'Marked as arrived.',
      'towing': 'Towing started.',
      'completed': 'Job completed.',
    };
    return map[next] ?? 'Status updated.';
  }

  IconData _nextStatusIcon(String current) {
    switch (current) {
      case 'accepted':
        return Icons.directions_car;
      case 'en_route':
        return Icons.place;
      case 'arrived':
        return Icons.local_shipping;
      case 'towing':
        return Icons.check_circle_outline;
      default:
        return Icons.check;
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch (_) {
      return iso;
    }
  }
}
