import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remote_mouse/providers/settings_provider.dart';
import 'package:remote_mouse/providers/web_socket_provider.dart';
import 'package:remote_mouse/screens/connection_screen.dart';
import 'package:remote_mouse/screens/settings_screen.dart';
import 'package:sensors_plus/sensors_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();
  Timer? _vScrollTimer;
  Timer? _hScrollTimer;
  double _vScrollDelta = 0.0;
  double _hScrollDelta = 0.0;

  // Gyroscope only - raw angular velocity
  double _gyroX = 0; // Tilt forward/back (vertical cursor movement)
  double _gyroY = 0; // Not used for cursor
  double _gyroZ = 0; // Pan left/right (horizontal cursor movement)

  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Calibration - gyro drift/bias when stationary
  double _gyroBiasX = 0;
  double _gyroBiasY = 0;
  double _gyroBiasZ = 0;

  // Smoothing - exponential moving average
  double _smoothGyroX = 0; // For vertical movement
  double _smoothGyroZ = 0; // For horizontal movement
  static const double kSmoothFactor = 0.3; // Lower = smoother but more lag

  // State
  bool _isCalibrated = false;
  bool _isCalibrating = false;
  bool _isActive = false;

  Timer? _updateTimer;

  // Sensitivity multiplier - converts rad/s to pixels
  static const double kGyroScaleX =
      40.0; // Vertical (X-axis) - tilt forward/back
  static const double kGyroScaleZ =
      60.0; // Horizontal (Z-axis) - pan left/right
  static const double kDeadzone = 0.02; // rad/s - ignore tiny movements

  @override
  void dispose() {
    _stopTracking();

    // Cancel timers first
    _vScrollTimer?.cancel();
    _hScrollTimer?.cancel();
    _vScrollTimer = null;
    _hScrollTimer = null;

    // Dispose controllers
    _vController.dispose();
    _hController.dispose();

    super.dispose();
  }

  void _startTracking() {
    setState(() {
      _isActive = true;
      _isCalibrated = false;
    });

    // Start gyroscope stream at highest rate
    _gyroscopeSubscription =
        gyroscopeEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen((event) {
          _gyroX = event.x;
          _gyroY = event.y;
          _gyroZ = event.z;
        });

    // Calibrate after sensors stabilize
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_isActive) _calibrate();
    });
  }

  void _stopTracking() {
    _updateTimer?.cancel();
    _gyroscopeSubscription?.cancel();

    setState(() {
      _isActive = false;
      _isCalibrated = false;
      _isCalibrating = false;
    });

    _resetState();
  }

  void _resetState() {
    _gyroX = 0;
    _gyroY = 0;
    _gyroZ = 0;
    _gyroBiasX = 0;
    _gyroBiasY = 0;
    _gyroBiasZ = 0;
    _smoothGyroX = 0;
    _smoothGyroZ = 0;
  }

  Future<void> _calibrate() async {
    setState(() => _isCalibrating = true);

    const int samples = 120; // 2 seconds at ~60Hz
    List<double> gyroXSamples = [];
    List<double> gyroYSamples = [];
    List<double> gyroZSamples = [];

    // Collect samples while phone is stationary
    for (int i = 0; i < samples; i++) {
      gyroXSamples.add(_gyroX);
      gyroYSamples.add(_gyroY);
      gyroZSamples.add(_gyroZ);
      await Future.delayed(const Duration(milliseconds: 16));
    }

    // Use median (more robust than mean)
    gyroXSamples.sort();
    gyroYSamples.sort();
    gyroZSamples.sort();

    final mid = samples ~/ 2;
    _gyroBiasX = gyroXSamples[mid];
    _gyroBiasY = gyroYSamples[mid];
    _gyroBiasZ = gyroZSamples[mid];

    debugPrint('Gyro calibration complete:');
    debugPrint('  Bias X: ${_gyroBiasX.toStringAsFixed(4)} rad/s');
    debugPrint('  Bias Y: ${_gyroBiasY.toStringAsFixed(4)} rad/s');
    debugPrint('  Bias Z: ${_gyroBiasZ.toStringAsFixed(4)} rad/s');

    setState(() {
      _isCalibrating = false;
      _isCalibrated = true;
    });

    _startUpdateLoop();
  }

  void _startUpdateLoop() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isActive || !_isCalibrated) {
        timer.cancel();
        return;
      }

      _sendMouseMovement();
      if (mounted) setState(() {});
    });
  }

  void _sendMouseMovement() {
    final ws = context.read<WebSocketProvider>();
    if (!ws.isConnected) return;

    final settings = context.read<SettingsProvider>();
    final sensitivity = settings.mouseSensitivity;

    // Get corrected gyro rates (rad/s)
    double gyroX = _gyroX - _gyroBiasX; // Tilt forward/back → vertical cursor
    double gyroZ = _gyroZ - _gyroBiasZ; // Pan left/right → horizontal cursor

    // Apply exponential smoothing
    _smoothGyroX = _smoothGyroX * (1 - kSmoothFactor) + gyroX * kSmoothFactor;
    _smoothGyroZ = _smoothGyroZ * (1 - kSmoothFactor) + gyroZ * kSmoothFactor;

    // Apply deadzone on smoothed values
    double finalX = _smoothGyroX.abs() > kDeadzone ? _smoothGyroX : 0;
    double finalZ = _smoothGyroZ.abs() > kDeadzone ? _smoothGyroZ : 0;

    // Map to cursor movement:
    // gyroZ (pan left/right) → horizontal cursor movement (dx)
    // gyroX (tilt forward/back) → vertical cursor movement (dy)
    final dx =
        -finalZ *
        sensitivity *
        kGyroScaleZ; // Pan left/right (negative to fix inversion)
    final dy =
        -finalX *
        sensitivity *
        kGyroScaleX; // Tilt forward/back (negative to fix inversion)

    // Only send if there's actual movement
    if (dx.abs() > 0.1 || dy.abs() > 0.1) {
      ws.sendMessage(
        jsonEncode({
          'action': 'move',
          'value': {'dx': dx.clamp(-35, 35), 'dy': dy.clamp(-35, 35)},
        }),
      );
    }
  }

  void _sendVScroll() {
    if (!mounted) return;

    final amount = (_vScrollDelta * 0.05).round();
    if (amount != 0) {
      context.read<WebSocketProvider>().sendMessage(
        jsonEncode({
          'action': 'scroll',
          'value': {'amount': amount},
        }),
      );
    }
    _vScrollDelta = 0.0;
  }

  void _sendHScroll() {
    if (!mounted) return;

    final amount = (_hScrollDelta * 0.05).round();
    if (amount != 0) {
      context.read<WebSocketProvider>().sendMessage(
        jsonEncode({
          'action': 'hscroll',
          'value': {'amount': amount},
        }),
      );
    }
    _hScrollDelta = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final ws = context.watch<WebSocketProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Mouse'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.qr_code_scanner_rounded),
          tooltip: 'Connect',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConnectionScreen()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Connection Status Banner
              if (!ws.isConnected)
                Card(
                  color: colorScheme.errorContainer,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.link_off_rounded,
                          size: 20,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Not connected to PC',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Mouse Control Area
              Expanded(
                child: Center(
                  child: _buildMouseControlArea(context, settings, ws),
                ),
              ),

              const SizedBox(height: 16),

              // Mouse Buttons and Scroll
              _buildMouseButtons(context, settings, ws),

              // Horizontal Scroll
              if (settings.horizontalScrolling) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: MouseWheel(
                            onChanged: (d) {
                              if (!mounted) return;
                              _hScrollDelta += d;
                              if (_hScrollTimer?.isActive != true) {
                                _hScrollTimer = Timer(
                                  const Duration(milliseconds: 50),
                                  _sendHScroll,
                                );
                              }
                            },
                            controller: _hController,
                            isHorizontal: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMouseControlArea(
    BuildContext context,
    SettingsProvider settings,
    WebSocketProvider ws,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth * 0.8
            : constraints.maxHeight * 0.6;

        return GestureDetector(
          onTap: () {
            if (settings.hapticFeedback) HapticFeedback.mediumImpact();

            if (!_isActive) {
              ws.setShouldStreamData(true);
              _startTracking();
            } else if (_isCalibrated) {
              if (settings.hapticFeedback) HapticFeedback.lightImpact();
              _calibrate();
            }
          },
          onLongPress: () {
            if (_isActive) {
              if (settings.hapticFeedback) HapticFeedback.heavyImpact();
              _stopTracking();
              ws.setShouldStreamData(false);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _isActive
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated ripple effect when active
                if (_isActive && _isCalibrated)
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeInOut,
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: size * 0.6,
                          height: size * 0.6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                    onEnd: () {
                      if (mounted && _isActive && _isCalibrated) {
                        setState(() {});
                      }
                    },
                  ),

                // Mouse Icon
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isActive ? Icons.mouse_rounded : Icons.mouse_outlined,
                      size: size * 0.35,
                      color: _isActive
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),

                    // Status Text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _isCalibrating
                            ? 'Calibrating...'
                            : _isCalibrated
                            ? 'Active'
                            : _isActive
                            ? 'Starting...'
                            : 'Tap to start',
                        key: ValueKey(
                          _isCalibrating
                              ? 'calibrating'
                              : _isCalibrated
                              ? 'calibrated'
                              : _isActive
                              ? 'starting'
                              : 'idle',
                        ),
                        style: textTheme.titleMedium?.copyWith(
                          color: _isActive
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Instructions
                    if (_isCalibrating)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Hold phone still',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer.withOpacity(
                              0.7,
                            ),
                          ),
                        ),
                      )
                    else if (_isActive && _isCalibrated)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              'Pan left/right & tilt forward/back',
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer
                                    .withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to recalibrate • Long press to stop',
                              textAlign: TextAlign.center,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!_isActive)
                      Text(
                        'Long press to stop',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),

                // Loading indicator
                if (_isCalibrating)
                  Positioned(
                    bottom: 24,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildMouseButtons(
    BuildContext context,
    SettingsProvider settings,
    WebSocketProvider ws,
  ) {
    return SizedBox(
      height: 100,
      child: Row(
        children: [
          Expanded(
            child: MouseButton(
              label: 'Left',
              icon: Icons.touch_app_rounded,
              onTapDown: () =>
                  ws.sendMessage(jsonEncode({'action': 'left_press'})),
              onTapUp: () =>
                  ws.sendMessage(jsonEncode({'action': 'left_release'})),
            ),
          ),
          if (settings.verticalScrolling) ...[
            const SizedBox(width: 12),
            MouseWheel(
              onChanged: (d) {
                if (!mounted) return;
                _vScrollDelta += d;
                if (_vScrollTimer?.isActive != true) {
                  _vScrollTimer = Timer(
                    const Duration(milliseconds: 50),
                    _sendVScroll,
                  );
                }
              },
              controller: _vController,
            ),
            const SizedBox(width: 12),
          ] else
            const SizedBox(width: 12),
          Expanded(
            child: MouseButton(
              label: 'Right',
              icon: Icons.touch_app_rounded,
              onTapDown: () =>
                  ws.sendMessage(jsonEncode({'action': 'right_press'})),
              onTapUp: () =>
                  ws.sendMessage(jsonEncode({'action': 'right_release'})),
            ),
          ),
        ],
      ),
    );
  }
}

class MouseButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const MouseButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  State<MouseButton> createState() => _MouseButtonState();
}

class _MouseButtonState extends State<MouseButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTapDown: (_) {
        if (settings.hapticFeedback) HapticFeedback.selectionClick();
        setState(() => _isPressed = true);
        widget.onTapDown();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTapUp();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.onTapUp();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _isPressed
              ? colorScheme.primary
              : colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: _isPressed
                    ? colorScheme.onPrimary
                    : colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: textTheme.titleSmall?.copyWith(
                  color: _isPressed
                      ? colorScheme.onPrimary
                      : colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MouseWheel extends StatelessWidget {
  final Function(double) onChanged;
  final ScrollController controller;
  final bool isHorizontal;

  const MouseWheel({
    super.key,
    required this.onChanged,
    required this.controller,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: isHorizontal ? double.infinity : 56,
      height: isHorizontal ? 56 : null,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollUpdateNotification && n.scrollDelta != null) {
              onChanged(n.scrollDelta!);
              if (settings.hapticFeedback) HapticFeedback.lightImpact();
            }
            return true;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            child: ListWheelScrollView.useDelegate(
              controller: controller,
              itemExtent: 8,
              diameterRatio: 1.2,
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (_, __) => Container(
                  color: colorScheme.onTertiaryContainer.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
