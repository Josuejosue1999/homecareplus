import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class ClinicNotificationPage extends StatefulWidget {
  final String clinicId;
  const ClinicNotificationPage({Key? key, required this.clinicId}) : super(key: key);

  @override
  State<ClinicNotificationPage> createState() => _ClinicNotificationPageState();
}

class _ClinicNotificationPageState extends State<ClinicNotificationPage> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isRefreshing = true;
    });
    
    // Attendre un peu pour montrer l'animation de rafraîchissement
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _markNotificationAsRead(AppointmentNotification notification) async {
    try {
      await NotificationService.markClinicNotificationAsRead(notification.id);
      print('Marked clinic notification as read: ${notification.id}');
    } catch (e) {
      print('Error marking clinic notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllClinicNotificationsAsRead(widget.clinicId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF159BBD),
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isRefreshing ? null : _refreshNotifications,
          ),
        ],
      ),
      body: StreamBuilder<List<AppointmentNotification>>(
        stream: NotificationService.getClinicNotifications(widget.clinicId),
        builder: (context, snapshot) {
          // État de chargement
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF159BBD),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des notifications...',
                    style: TextStyle(
                      color: Color(0xFF159BBD),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // État d'erreur
          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final notifications = snapshot.data ?? [];

          // État vide
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          // Liste des notifications
          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            color: const Color(0xFF159BBD),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(notifications[index]);
              },
            ),
          );
        },
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
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vérifiez votre connexion et réessayez.',
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
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF159BBD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
            Icon(
              Icons.notifications_none,
              size: 48,
              color: const Color(0xFF159BBD),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune notification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous verrez les notifications ici quand un rendez-vous sera réservé ou approuvé.',
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
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF159BBD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppointmentNotification notification) {
    return GestureDetector(
      onTap: () => _markNotificationAsRead(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: notification.isRead 
                  ? Colors.black.withOpacity(0.02)
                  : Colors.black.withOpacity(0.06),
              spreadRadius: 0,
              blurRadius: notification.isRead ? 2 : 6,
              offset: const Offset(0, 1),
            ),
          ],
          border: notification.isRead 
              ? Border.all(color: Colors.grey.withOpacity(0.1), width: 0.5)
              : Border.all(color: const Color(0xFF159BBD).withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicateur de lecture et icône
              Column(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: notification.isRead 
                          ? Colors.transparent
                          : const Color(0xFF159BBD),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: notification.isRead 
                          ? Colors.grey.withOpacity(0.1)
                          : const Color(0xFF159BBD).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: notification.isRead 
                          ? Colors.grey[600]
                          : const Color(0xFF159BBD),
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Contenu principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre et heure
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead 
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: notification.isRead 
                                  ? Colors.grey[700]
                                  : const Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy • HH:mm').format(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: notification.isRead 
                                ? Colors.grey[500]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Message
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: notification.isRead 
                            ? Colors.grey[600]
                            : const Color(0xFF2C3E50),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Informations supplémentaires
                    if (notification.hospitalName?.isNotEmpty == true && 
                        notification.department?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF159BBD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${notification.hospitalName}${notification.department?.isNotEmpty == true && notification.department != 'General' ? ' - ${notification.department}' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF159BBD),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    
                    // Date et heure du rendez-vous
                    if (notification.appointmentDate != null || notification.appointmentTime?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 16,
                            color: Color(0xFF159BBD),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatAppointmentDateTime(notification),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF159BBD),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Badge de type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: notification.isRead 
                      ? Colors.grey.withOpacity(0.1)
                      : const Color(0xFF159BBD).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CLINIC',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: notification.isRead 
                        ? Colors.grey[600]
                        : const Color(0xFF159BBD),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAppointmentDateTime(AppointmentNotification notification) {
    if (notification.appointmentDate != null && notification.appointmentTime?.isNotEmpty == true) {
      return '${DateFormat('MMM dd').format(notification.appointmentDate!)} at ${notification.appointmentTime}';
    } else if (notification.appointmentDate != null) {
      return '${DateFormat('MMM dd').format(notification.appointmentDate!)}';
    } else if (notification.appointmentTime?.isNotEmpty == true) {
      return notification.appointmentTime!;
    } else {
      return '';
    }
  }
} 