import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:remote_mouse/providers/web_socket_provider.dart';
import 'package:remote_mouse/screens/home_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> with SingleTickerProviderStateMixin {
  bool _isConnecting = false;
  late AnimationController _animationController;
  late Animation<double> _borderPulseAnimation;

  @override
  void initState() {
    super.initState();
    // Animation for pulsing QR overlay border
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _borderPulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final webSocketProvider = context.read<WebSocketProvider>();

    return Scaffold(
      // Modern AppBar with subtle elevation
      appBar: AppBar(
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
        backgroundColor: theme.colorScheme.surfaceContainer,
        title: Text(
          'Connect to PC',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      // Gradient background for classy look
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Stack(
          children: [
            MobileScanner(
              onDetect: (barcodes) async {
                if (_isConnecting) return;

                setState(() => _isConnecting = true);

                debugPrint('Barcode found! ${barcodes.barcodes.first.rawValue}');

                String url = barcodes.barcodes.first.rawValue!;
                url = url.replaceAll('#', '').trim();

                webSocketProvider.setConnectionUrl(url);
                final bool connected = await webSocketProvider.connect();
                if (context.mounted) {
                  if (connected) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  } else {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: theme.colorScheme.surfaceContainerLow,
                        title: Text(
                          'Connection Failed',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          'Unable to connect to your desktop. Ensure both devices are on the same network and the server is running.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                    if (mounted) {
                      setState(() => _isConnecting = false);
                    }
                  }
                }
              },
              placeholderBuilder: (context) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_off,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Camera Detected',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please grant camera permissions to scan the QR code.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              overlayBuilder: (context, constraints) => Center(
                child: AnimatedBuilder(
                  animation: _borderPulseAnimation,
                  builder: (context, _) => Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(_borderPulseAnimation.value),
                        width: 4 * _borderPulseAnimation.value,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2 * _borderPulseAnimation.value),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Connecting overlay
            if (_isConnecting)
              Container(
                color: theme.colorScheme.surface.withOpacity(0.8),
                child: Center(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connecting to Desktop...',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Instructions at bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Scan the QR code displayed on your desktop to connect.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}