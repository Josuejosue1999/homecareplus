import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> 
    with TickerProviderStateMixin {
  bool _isRefreshing = false;
  List<AppointmentNotification> _notifications = [];
  
  // Animation controllers for bubbles
  late AnimationController _bubbleController1;
  late AnimationController _bubbleController2;
  late AnimationController _bubbleController3;
  late AnimationController _bubbleController4;
  
  // Bubble animations
  late Animation<Offset> _bubbleAnimation1;
  late Animation<Offset> _bubbleAnimation2;
  late Animation<Offset> _bubbleAnimation3;
  late Animation<Offset> _bubbleAnimation4;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadNotifications();
  }

  void _initializeAnimations() {
    // Initialize bubble animation controllers
    _bubbleController1 = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _bubbleController2 = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );
    _bubbleController3 = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _bubbleController4 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    // Initialize bubble position animations
    _bubbleAnimation1 = Tween<Offset>(
      begin: const Offset(-0.5, 1.5),
      end: const Offset(1.5, -0.5),
    ).animate(CurvedAnimation(
      parent: _bubbleController1,
      curve: Curves.linear,
    ));

    _bubbleAnimation2 = Tween<Offset>(
      begin: const Offset(1.5, 1.2),
      end: const Offset(-0.5, -0.8),
    ).animate(CurvedAnimation(
      parent: _bubbleController2,
      curve: Curves.linear,
    ));

    _bubbleAnimation3 = Tween<Offset>(
      begin: const Offset(0.5, 1.8),
      end: const Offset(-1.2, -0.3),
    ).animate(CurvedAnimation(
      parent: _bubbleController3,
      curve: Curves.linear,
    ));

    _bubbleAnimation4 = Tween<Offset>(
      begin: const Offset(-1.0, 1.0),
      end: const Offset(1.8, -1.0),
    ).animate(CurvedAnimation(
      parent: _bubbleController4,
      curve: Curves.linear,
    ));

    // Start animations
    _bubbleController1.repeat();
    _bubbleController2.repeat();
    _bubbleController3.repeat();
    _bubbleController4.repeat();
  }

  @override
  void dispose() {
    _bubbleController1.dispose();
    _bubbleController2.dispose();
    _bubbleController3.dispose();
    _bubbleController4.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await NotificationService.getPatientNotifications().first;
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isRefreshing = true;
    });
    
    await _loadNotifications();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _markNotificationAsRead(AppointmentNotification notification) async {
    if (!notification.isRead) {
      await NotificationService.markNotificationAsRead(notification.id);
      await _loadNotifications();
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllNotificationsAsRead();
    await _loadNotifications();
  }

  Future<void> _deleteNotification(AppointmentNotification notification) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Notification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this notification? This action cannot be undone.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF4A5568),
              height: 1.4,
            ),
          ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldDelete == true) {
        // Delete from Firebase
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notification.id)
            .delete();

        // Update local state
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Notification deleted successfully',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to delete notification. Please try again.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Animated bubbles background
          _buildAnimatedBubbles(),
          
          // Main content
          Column(
            children: [
              // Enhanced header with bubbles
              _buildEnhancedHeader(),
              
              // Notifications content
              Expanded(
                child: StreamBuilder<List<AppointmentNotification>>(
                  stream: NotificationService.getPatientNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return _buildLoadingState();
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState();
                    }

                    final notifications = snapshot.data ?? [];

                    if (notifications.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildNotificationsList(notifications);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBubbles() {
    return Stack(
      children: [
        // Bubble 1
        AnimatedBuilder(
          animation: _bubbleAnimation1,
          builder: (context, child) {
            return Positioned(
              left: MediaQuery.of(context).size.width * _bubbleAnimation1.value.dx,
              top: MediaQuery.of(context).size.height * _bubbleAnimation1.value.dy,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF159BBD).withOpacity(0.1),
                      const Color(0xFF159BBD).withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Bubble 2
        AnimatedBuilder(
          animation: _bubbleAnimation2,
          builder: (context, child) {
            return Positioned(
              left: MediaQuery.of(context).size.width * _bubbleAnimation2.value.dx,
              top: MediaQuery.of(context).size.height * _bubbleAnimation2.value.dy,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6B6B).withOpacity(0.1),
                      const Color(0xFFFF6B6B).withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Bubble 3
        AnimatedBuilder(
          animation: _bubbleAnimation3,
          builder: (context, child) {
            return Positioned(
              left: MediaQuery.of(context).size.width * _bubbleAnimation3.value.dx,
              top: MediaQuery.of(context).size.height * _bubbleAnimation3.value.dy,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4ECDC4).withOpacity(0.1),
                      const Color(0xFF4ECDC4).withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Bubble 4
        AnimatedBuilder(
          animation: _bubbleAnimation4,
          builder: (context, child) {
            return Positioned(
              left: MediaQuery.of(context).size.width * _bubbleAnimation4.value.dx,
              top: MediaQuery.of(context).size.height * _bubbleAnimation4.value.dy,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFE66D).withOpacity(0.1),
                      const Color(0xFFFFE66D).withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF159BBD),
            const Color(0xFF159BBD).withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF159BBD).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Header bubbles
          AnimatedBuilder(
            animation: _bubbleAnimation1,
            builder: (context, child) {
              return Positioned(
                left: _bubbleAnimation1.value.dx * 300,
                top: _bubbleAnimation1.value.dy * 100,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _bubbleAnimation2,
            builder: (context, child) {
              return Positioned(
                right: _bubbleAnimation2.value.dx * 200,
                top: _bubbleAnimation2.value.dy * 80,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.03),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _bubbleAnimation3,
            builder: (context, child) {
              return Positioned(
                left: _bubbleAnimation3.value.dx * 250,
                bottom: _bubbleAnimation3.value.dy * 60,
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Header content
          Column(
            children: [
              // Header row with back button and actions
              Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  
                  const SizedBox(width: 15),
                  
                  // Title only (removed subtitle)
                  const Expanded(
                    child: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
                        fontSize: 24,
            fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  // Actions
                  Row(
                    children: [
                      // Mark all as read button
                      StreamBuilder<List<AppointmentNotification>>(
                        stream: NotificationService.getPatientNotifications(),
                        builder: (context, snapshot) {
                          final notifications = snapshot.data ?? [];
                          final hasUnread = notifications.any((n) => !n.isRead);
                          
                          if (!hasUnread) return const SizedBox.shrink();
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.done_all, color: Colors.white, size: 20),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
                          );
                        },
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // Refresh button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                              : const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: _isRefreshing ? null : _refreshNotifications,
                          tooltip: 'Refresh',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Stats row
              StreamBuilder<List<AppointmentNotification>>(
                stream: NotificationService.getPatientNotifications(),
                builder: (context, snapshot) {
                  final notifications = snapshot.data ?? [];
                  final totalCount = notifications.length;
                  final unreadCount = notifications.where((n) => !n.isRead).length;
                  
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.notifications,
                          title: 'Total',
                          value: totalCount.toString(),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.circle_notifications,
                          title: 'Unread',
                          value: unreadCount.toString(),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
                    color: Color(0xFF159BBD),
              strokeWidth: 3,
            ),
                  ),
          const SizedBox(height: 20),
          const Text(
                    'Loading notifications...',
                    style: TextStyle(
                      color: Color(0xFF159BBD),
                      fontSize: 16,
              fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your connection and try again.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF159BBD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
              Icons.notifications_none,
                size: 60,
              color: const Color(0xFF159BBD),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You will receive notifications here\nwhen your appointments are updated.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _refreshNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF159BBD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<AppointmentNotification> notifications) {
    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: const Color(0xFF159BBD),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _buildProfessionalNotificationCard(notifications[index]);
        },
      ),
    );
  }

  Widget _buildProfessionalNotificationCard(AppointmentNotification notification) {
    return GestureDetector(
      onTap: () => _markNotificationAsRead(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: notification.isRead 
                  ? Colors.black.withOpacity(0.05)
                  : const Color(0xFF159BBD).withOpacity(0.1),
              blurRadius: notification.isRead ? 10 : 15,
              offset: const Offset(0, 5),
              spreadRadius: notification.isRead ? 0 : 2,
            ),
          ],
          border: notification.isRead 
              ? null
              : Border.all(
                  color: const Color(0xFF159BBD).withOpacity(0.2),
                  width: 1,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: notification.isRead 
                          ? Colors.grey.withOpacity(0.3)
                          : const Color(0xFF159BBD),
                      shape: BoxShape.circle,
                      boxShadow: notification.isRead 
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF159BBD).withOpacity(0.3),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                    ),
                  ),
                  
                  const SizedBox(width: 15),
                  
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: notification.isRead 
                          ? Colors.grey.withOpacity(0.1)
                          : const Color(0xFF159BBD).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      notification.typeIcon,
                      color: notification.isRead 
                          ? Colors.grey[600]
                          : const Color(0xFF159BBD),
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 15),
              
                  // Title and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            notification.title == "Appointment Booked successfully" 
                              ? "Appointment booked and Pending"
                              : notification.title,
                            style: TextStyle(
                            fontSize: 16,
                              fontWeight: notification.isRead 
                                ? FontWeight.w600
                                  : FontWeight.bold,
                              color: notification.isRead 
                                  ? Colors.grey[700]
                                  : const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 2),
                        
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: notification.isRead 
                                    ? Colors.grey.withOpacity(0.1)
                                    : const Color(0xFF159BBD).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                notification.isRead ? 'READ' : 'NEW',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: notification.isRead 
                                      ? Colors.grey[600]
                                      : const Color(0xFF159BBD),
                            ),
                          ),
                        ),
                            const SizedBox(width: 8),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 15),
                    
                    // Message
                    Text(
                      notification.message,
                      style: TextStyle(
                  fontSize: 14,
                        color: notification.isRead 
                            ? Colors.grey[600]
                            : const Color(0xFF2C3E50),
                  fontWeight: notification.isRead 
                      ? FontWeight.w400
                      : FontWeight.w500,
                  height: 1.4,
                ),
              ),
              
              // Appointment details
              if (notification.appointmentDate != null || notification.appointmentTime?.isNotEmpty == true) ...[
                const SizedBox(height: 15),
                      Container(
                  padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                    color: const Color(0xFF159BBD).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                          color: const Color(0xFF159BBD).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 18,
                        color: const Color(0xFF159BBD),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formatAppointmentDateTime(notification),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF159BBD),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatAppointmentDateTime(AppointmentNotification notification) {
    if (notification.appointmentDate != null && notification.appointmentTime?.isNotEmpty == true) {
      return '${DateFormat('dd MMM yyyy').format(notification.appointmentDate!)} à ${notification.appointmentTime}';
    } else if (notification.appointmentDate != null) {
      return '${DateFormat('dd MMM yyyy').format(notification.appointmentDate!)}';
    } else if (notification.appointmentTime?.isNotEmpty == true) {
      return notification.appointmentTime!;
    } else {
      return '';
    }
  }
} 