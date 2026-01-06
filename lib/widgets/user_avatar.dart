import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final double size;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    
    if (avatarUrl.startsWith('http') || avatarUrl.startsWith('blob:') || avatarUrl.startsWith('data:')) {
      imageProvider = CachedNetworkImageProvider(avatarUrl);
    } else if (avatarUrl.isNotEmpty) {
      // For local files on mobile/desktop, or other paths
      // Note: On web, x_file.path usually provides a blob URL which starts with 'blob:'
      imageProvider = NetworkImage(avatarUrl);
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: size / 2,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            )
          : null,
    );
  }
}