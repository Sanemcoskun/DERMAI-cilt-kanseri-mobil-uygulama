import 'package:flutter/material.dart';
import '../main_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Örnek bildirim verileri
  final List<NotificationItem> _allNotifications = [
    NotificationItem(
      id: '1',
      title: 'Analiz Tamamlandı',
      message: 'Cilt analiziniz başarıyla tamamlandı. Sonuçları görüntülemek için tıklayın.',
      type: NotificationType.analysis,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Günlük Hatırlatma',
      message: 'Güneş kremi kullanmayı unutmayın! Cildinizi UV ışınlarından koruyun.',
      type: NotificationType.reminder,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'Yeni Blog Yazısı',
      message: 'Kış aylarında cilt bakımı hakkında yeni bir makale yayınlandı.',
      type: NotificationType.blog,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: 'Premium Özellik',
      message: 'AI danışmanlık hizmeti artık aktif! Uzman tavsiyeleri için deneyin.',
      type: NotificationType.feature,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      title: 'Randevu Hatırlatması',
      message: 'Yarın saat 14:00\'da doktor randevunuz bulunmaktadır.',
      type: NotificationType.appointment,
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      isRead: false,
    ),
    NotificationItem(
      id: '6',
      title: 'Sistem Güncelleme',
      message: 'Uygulama güncellemesi mevcut. Yeni özellikler ve iyileştirmeler içeriyor.',
      type: NotificationType.system,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<NotificationItem> get _unreadNotifications => 
    _allNotifications.where((notification) => !notification.isRead).toList();

  List<NotificationItem> get _readNotifications => 
    _allNotifications.where((notification) => notification.isRead).toList();

  void _markAsRead(String notificationId) {
    setState(() {
      final index = _allNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _allNotifications[index] = _allNotifications[index].copyWith(isRead: true);
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _allNotifications.length; i++) {
        _allNotifications[i] = _allNotifications[i].copyWith(isRead: true);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tüm bildirimler okundu olarak işaretlendi'),
        backgroundColor: Color(0xFF05a5a5),
      ),
    );
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      _allNotifications.removeWhere((n) => n.id == notificationId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bildirim silindi'),
        backgroundColor: Color(0xFF05a5a5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05a5a5),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Bildirimler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_unreadNotifications.isNotEmpty)
            IconButton(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all),
              tooltip: 'Tümünü Okundu İşaretle',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'settings') {
                _showNotificationSettings();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Bildirim Ayarları'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              text: 'Okunmamış (${_unreadNotifications.length})',
            ),
            Tab(
              text: 'Tümü (${_allNotifications.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Okunmamış bildirimler
          _buildNotificationsList(_unreadNotifications, showEmptyUnread: true),
          // Tüm bildirimler
          _buildNotificationsList(_allNotifications, showEmptyUnread: false),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationItem> notifications, {required bool showEmptyUnread}) {
    if (notifications.isEmpty) {
      return _buildEmptyState(showEmptyUnread);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildEmptyState(bool showEmptyUnread) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF05a5a5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              showEmptyUnread ? Icons.notifications_off_outlined : Icons.notifications_outlined,
              size: 64,
              color: const Color(0xFF05a5a5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            showEmptyUnread ? 'Okunmamış bildirim yok' : 'Henüz bildirim yok',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showEmptyUnread 
              ? 'Tüm bildirimlerinizi okudunuz 🎉' 
              : 'Bildirimleriniz burada görünecek',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: notification.isRead 
          ? null 
          : Border.all(color: const Color(0xFF05a5a5).withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) => _deleteNotification(notification.id),
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 24,
          ),
        ),
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              _markAsRead(notification.id);
            }
            _handleNotificationTap(notification);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                                color: const Color(0xFF1A202C),
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF05a5a5),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                          fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.analysis:
        return Icons.analytics;
      case NotificationType.reminder:
        return Icons.access_time;
      case NotificationType.blog:
        return Icons.article;
      case NotificationType.feature:
        return Icons.star;
      case NotificationType.appointment:
        return Icons.calendar_today;
      case NotificationType.system:
        return Icons.system_update;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.analysis:
        return const Color(0xFF05a5a5);
      case NotificationType.reminder:
        return const Color(0xFFFF9800);
      case NotificationType.blog:
        return const Color(0xFF7C3AED);
      case NotificationType.feature:
        return const Color(0xFFEC4899);
      case NotificationType.appointment:
        return const Color(0xFF059669);
      case NotificationType.system:
        return const Color(0xFF64748B);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} sa önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Bildirim türüne göre farklı işlemler yapılabilir
    switch (notification.type) {
      case NotificationType.analysis:
        // Analiz sayfasına yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreen(initialIndex: 2),
          ),
        );
        break;
      case NotificationType.blog:
        // Blog sayfasına yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreen(initialIndex: 1),
          ),
        );
        break;
      default:
        // Varsayılan işlem
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notification.title} bildirimi açıldı'),
            backgroundColor: const Color(0xFF05a5a5),
          ),
        );
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildNotificationSettings(),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bildirim Ayarları',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingTile(
            icon: Icons.analytics,
            title: 'Analiz Bildirimleri',
            subtitle: 'Analiz sonuçları için bildirim al',
            value: true,
          ),
          _buildSettingTile(
            icon: Icons.access_time,
            title: 'Hatırlatma Bildirimleri',
            subtitle: 'Günlük bakım hatırlatmaları',
            value: true,
          ),
          _buildSettingTile(
            icon: Icons.article,
            title: 'Blog Bildirimleri',
            subtitle: 'Yeni makale yayınlarında bildir',
            value: false,
          ),
          _buildSettingTile(
            icon: Icons.star,
            title: 'Özellik Bildirimleri',
            subtitle: 'Yeni özellikler hakkında bilgi al',
            value: true,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF05a5a5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF05a5a5),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A202C),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              // Ayar değişikliği işlemi
            },
            activeColor: const Color(0xFF05a5a5),
          ),
        ],
      ),
    );
  }
}

// Bildirim modeli
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

// Bildirim türleri
enum NotificationType {
  analysis,    // Analiz bildirimleri
  reminder,    // Hatırlatma bildirimleri
  blog,        // Blog bildirimleri
  feature,     // Yeni özellik bildirimleri
  appointment, // Randevu bildirimleri
  system,      // Sistem bildirimleri
} 