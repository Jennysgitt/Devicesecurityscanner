import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/supabase_service.dart';
import '../models/device_model.dart';
import '../models/verification_log_model.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<DeviceModel> _recentDevices = [];
  List<VerificationLogModel> _recentVerifications = [];
  Map<String, int> _stats = {
    'totalDevices': 0,
    'verifiedToday': 0,
    'activeAlerts': 0,
    'blocked': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      
      // Load all devices
      final allDevices = await supabaseService.getDevices();
      
      // Load verification logs
      final verificationLogs = await supabaseService.getVerificationLogs(limit: 50);
      
      // Calculate stats
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final verifiedToday = verificationLogs.where((log) {
        return log.createdAt.isAfter(todayStart) && log.status == 'verified';
      }).length;
      
      final activeAlerts = verificationLogs.where((log) {
        return log.status == 'suspicious' || log.status == 'blocked';
      }).length;
      
      final blocked = verificationLogs.where((log) {
        return log.status == 'blocked';
      }).length;

      if (mounted) {
        setState(() {
          _stats = {
            'totalDevices': allDevices.length,
            'verifiedToday': verifiedToday,
            'activeAlerts': activeAlerts,
            'blocked': blocked,
          };
          _recentDevices = allDevices.take(5).toList();
          _recentVerifications = verificationLogs.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Dashboard',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadDashboardData,
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                'Overview',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // KPI Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildKPICard(
                                      'Total Devices',
                                      _stats['totalDevices'].toString(),
                                      Icons.devices,
                                      AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildKPICard(
                                      'Verified Today',
                                      _stats['verifiedToday'].toString(),
                                      Icons.verified,
                                      AppTheme.successGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildKPICard(
                                      'Active Alerts',
                                      _stats['activeAlerts'].toString(),
                                      Icons.warning,
                                      AppTheme.warningOrange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildKPICard(
                                      'Blocked',
                                      _stats['blocked'].toString(),
                                      Icons.block,
                                      AppTheme.errorRed,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'Recent Devices',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildRecentDevicesList(),
                              const SizedBox(height: 24),
                              const Text(
                                'Recent Verifications',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildRecentVerificationsList(),
                              const SizedBox(height: 20),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDevicesList() {
    if (_recentDevices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'No devices yet',
          style: TextStyle(color: AppTheme.textMedium),
        ),
      );
    }

    return Column(
      children: _recentDevices.map((device) {
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.lightGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${device.brand} ${device.model}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.qrCodeUrl != null ? 'Verified' : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: device.qrCodeUrl != null
                            ? AppTheme.successGreen
                            : AppTheme.warningOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textLight,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentVerificationsList() {
    if (_recentVerifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'No verifications yet',
          style: TextStyle(color: AppTheme.textMedium),
        ),
      );
    }

    return Column(
      children: _recentVerifications.map((verification) {
        final status = verification.status;
        Color statusColor;
        IconData statusIcon;

        switch (status) {
          case 'verified':
            statusColor = AppTheme.successGreen;
            statusIcon = Icons.check_circle;
            break;
          case 'suspicious':
            statusColor = AppTheme.warningOrange;
            statusIcon = Icons.warning;
            break;
          default:
            statusColor = AppTheme.errorRed;
            statusIcon = Icons.block;
        }

        final timeAgo = _getTimeAgo(verification.createdAt);

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device ${verification.deviceId.substring(0, 8)}...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}
