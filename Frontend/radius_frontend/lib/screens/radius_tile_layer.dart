import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

const List<double> _darkTileMatrix = <double>[
  0.574, -1.430, -0.144, 0, 255,
  -0.426, -0.430, -0.144, 0, 255,
  -0.426, -1.430, 0.856, 0, 255,
  0, 0, 0, 1, 0,
];

TileLayer radiusTileLayer(BuildContext context) {
  final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.eddie.radiusFrontend',
    tileBuilder: isDark
        ? (context, tileWidget, tile) => ColorFiltered(
              colorFilter: const ColorFilter.matrix(_darkTileMatrix),
              child: tileWidget,
            )
        : null,
  );
}

Widget radiusAttribution() {
  return RichAttributionWidget(
    attributions: [
      TextSourceAttribution(
        'OpenStreetMap contributors',
        onTap: () => launchUrl(
          Uri.parse('https://www.openstreetmap.org/copyright'),
          mode: LaunchMode.externalApplication,
        ),
      ),
    ],
  );
}