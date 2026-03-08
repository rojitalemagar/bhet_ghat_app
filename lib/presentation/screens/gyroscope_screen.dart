import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class GyroscopeScreen extends StatelessWidget {
  const GyroscopeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text('Gyroscope'),
      ),
      body: StreamBuilder<GyroscopeEvent>(
        stream: gyroscopeEventStream(),
        builder: (context, snapshot) {
          final event = snapshot.data;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isShort = constraints.maxHeight < 480;
              final horizontalPadding = isShort ? 16.0 : 24.0;
              final verticalPadding = isShort ? 12.0 : 24.0;
              final cardPadding = isShort ? 16.0 : 24.0;
              final iconSize = isShort ? 40.0 : 56.0;
              final titleSpacing = isShort ? 10.0 : 16.0;
              final sectionSpacing = isShort ? 14.0 : 20.0;
              final rowSpacing = isShort ? 8.0 : 12.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.rotate_right,
                            size: iconSize,
                            color: Colors.green,
                          ),
                          SizedBox(height: titleSpacing),
                          Text(
                            'Gyroscope',
                            style: TextStyle(
                              fontSize: isShort ? 20 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: sectionSpacing),
                          _AxisValue(
                            label: 'X',
                            value: event?.x,
                            color: Colors.green,
                            compact: isShort,
                          ),
                          SizedBox(height: rowSpacing),
                          _AxisValue(
                            label: 'Y',
                            value: event?.y,
                            color: Colors.teal,
                            compact: isShort,
                          ),
                          SizedBox(height: rowSpacing),
                          _AxisValue(
                            label: 'Z',
                            value: event?.z,
                            color: Colors.lightGreen,
                            compact: isShort,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AxisValue extends StatelessWidget {
  const _AxisValue({
    required this.label,
    required this.value,
    required this.color,
    required this.compact,
  });

  final String label;
  final double? value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: compact ? 16 : 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 14,
              ),
            ),
          ),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Text(
              value == null
                  ? 'Waiting for sensor...'
                  : value!.toStringAsFixed(2),
              style: TextStyle(
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
