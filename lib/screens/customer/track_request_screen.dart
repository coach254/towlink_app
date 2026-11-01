import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TrackRequestScreen extends StatefulWidget {
  const TrackRequestScreen({super.key, required this.requestId});

  final int requestId;

  @override
  State<TrackRequestScreen> createState() => _TrackRequestScreenState();
}

class _TrackRequestScreenState extends State<TrackRequestScreen> {
  static const String baseUrl = 'http://10.0.2.2:8765';

  Map<String, dynamic>? _request;
  Map<String, dynamic>? _driver;
  Timer? _timer;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/tow-requests/${widget.requestId}'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Could not load request.');
      }

      final request = jsonDecode(response.body) as Map<String, dynamic>;

      Map<String, dynamic>? driver;
      final driverId = request['assigned_driver_id'];
      if (driverId is int) {
        final dResponse = await http
            .get(Uri.parse('$baseUrl/drivers/$driverId'))
            .timeout(const Duration(seconds: 10));
        if (dResponse.statusCode == 200) {
          driver = jsonDecode(dResponse.body) as Map<String, dynamic>;
        }
      }

      if (!mounted) return;
      setState(() {
        _request = request;
        _driver = driver;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not refresh. Retrying...';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _request?['status'] as String? ?? 'requested';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Text('Request #${widget.requestId}'),
        actions: [
          IconButton(
            tooltip: 'Refresh now',
            icon: const Icon(Icons.refresh),
            onPressed: _fetch,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _headerCard(status),
              const SizedBox(height: 20),
              if (_driver != null) _driverCard(),
              if (_driver == null) _searchingCard(),
              const SizedBox(height: 20),
              _progressTimeline(status),
              const SizedBox(height: 20),
              if (_request != null) _detailsCard(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              if (_loading) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard(String status) {
    final info = _statusInfo(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: info.color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(info.icon, color: Colors.white, size: 42),
          const SizedBox(height: 14),
          Text(
            info.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            info.subtitle,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _driverCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your driver',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              _driver!['full_name'].toString(),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Phone: ${_driver!['phone']}'),
            Text('Vehicle: ${_driver!['vehicle_type']}'),
            Text('Plate: ${_driver!['vehicle_registration']}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Call ${_driver!['phone']} (dialer not wired yet)',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call driver'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchingCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Finding a nearby tow truck...',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressTimeline(String status) {
    const stages = [
      ('requested', 'Request received', Icons.receipt_long),
      ('accepted', 'Driver assigned', Icons.person_pin_circle),
      ('en_route', 'On the way', Icons.directions_car),
      ('arrived', 'Arrived at pickup', Icons.place),
      ('towing', 'Towing in progress', Icons.local_shipping),
      ('completed', 'Completed', Icons.check_circle),
    ];

    final currentIndex = stages.indexWhere((s) => s.$1 == status).clamp(0, 5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...List.generate(stages.length, (i) {
              final done = i < currentIndex;
              final active = i == currentIndex;
              final color = done
                  ? const Color(0xFF2E7D32)
                  : active
                  ? const Color(0xFF1565C0)
                  : Colors.grey.shade400;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(stages[i].$3, color: color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        stages[i].$2,
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF1565C0)
                              : Colors.black87,
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (done || active)
                      Icon(Icons.check, color: color, size: 18),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _detailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text('Pickup: ${_request!['pickup_location']}'),
            Text('Destination: ${_request!['destination'] ?? 'Not specified'}'),
            Text('Vehicle: ${_request!['vehicle_type']}'),
            Text('Problem: ${_request!['problem_description']}'),
          ],
        ),
      ),
    );
  }

  ({String title, String subtitle, IconData icon, Color color}) _statusInfo(
    String status,
  ) {
    switch (status) {
      case 'requested':
        return (
          title: 'Finding a driver...',
          subtitle: 'We are notifying nearby tow trucks.',
          icon: Icons.search,
          color: const Color(0xFF1565C0),
        );
      case 'accepted':
        return (
          title: 'Driver assigned',
          subtitle: 'Your driver is getting ready to move.',
          icon: Icons.person_pin_circle,
          color: const Color(0xFF1565C0),
        );
      case 'en_route':
        return (
          title: 'On the way',
          subtitle: 'Your driver is heading to your pickup point.',
          icon: Icons.directions_car,
          color: const Color(0xFFF59E0B),
        );
      case 'arrived':
        return (
          title: 'Driver arrived',
          subtitle: 'Your driver is at the pickup location.',
          icon: Icons.place,
          color: const Color(0xFF6D28D9),
        );
      case 'towing':
        return (
          title: 'Towing in progress',
          subtitle: 'Your vehicle is on the way to the destination.',
          icon: Icons.local_shipping,
          color: const Color(0xFFDC2626),
        );
      case 'completed':
        return (
          title: 'Tow completed',
          subtitle: 'Thank you for using TowLink Ghana.',
          icon: Icons.check_circle,
          color: const Color(0xFF16A34A),
        );
      default:
        return (
          title: 'Request status',
          subtitle: status,
          icon: Icons.info_outline,
          color: const Color(0xFF1565C0),
        );
    }
  }
}
