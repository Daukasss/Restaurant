import 'package:flutter/material.dart';

class PhotoGallery extends StatelessWidget {
  final List<String> photoUrls;
  final Function() onAddPhoto;
  final Function(int) onRemovePhoto;

  const PhotoGallery({
    super.key,
    required this.photoUrls,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: photoUrls.isEmpty
          ? Center(
              child: TextButton.icon(
                onPressed: onAddPhoto,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Photos'),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photoUrls.length + 1,
              itemBuilder: (context, index) {
                if (index == photoUrls.length) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: onAddPhoto,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photoUrls[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () => onRemovePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
