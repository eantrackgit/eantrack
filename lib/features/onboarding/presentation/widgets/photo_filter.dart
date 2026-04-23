import 'dart:typed_data';

import 'package:flutter/material.dart';

enum PhotoFilter {
  original(
    label: 'Original',
    matrix: null,
  ),
  natural(
    label: 'Natural',
    matrix: <double>[
      1.04, 0.00, 0.00, 0.00, 4.0,
      0.00, 1.02, 0.00, 0.00, 2.0,
      0.00, 0.00, 0.98, 0.00, -3.0,
      0.00, 0.00, 0.00, 1.00, 0.0,
    ],
  ),
  vibrant(
    label: 'Vibrante',
    matrix: <double>[
      1.12, -0.05, -0.05, 0.00, 6.0,
      -0.04, 1.10, -0.04, 0.00, 4.0,
      -0.03, -0.03, 1.14, 0.00, 5.0,
      0.00, 0.00, 0.00, 1.00, 0.0,
    ],
  ),
  blackAndWhite(
    label: 'Preto & Branco',
    matrix: <double>[
      0.2126, 0.7152, 0.0722, 0.00, 0.0,
      0.2126, 0.7152, 0.0722, 0.00, 0.0,
      0.2126, 0.7152, 0.0722, 0.00, 0.0,
      0.0000, 0.0000, 0.0000, 1.00, 0.0,
    ],
  );

  const PhotoFilter({
    required this.label,
    required this.matrix,
  });

  final String label;
  final List<double>? matrix;

  ColorFilter? get colorFilter {
    final matrix = this.matrix;
    if (matrix == null) return null;
    return ColorFilter.matrix(matrix);
  }
}

class FilterSelector extends StatelessWidget {
  const FilterSelector({
    required this.photoBytes,
    required this.selectedFilter,
    required this.onSelected,
  });

  final Uint8List? photoBytes;
  final PhotoFilter selectedFilter;
  final ValueChanged<PhotoFilter>? onSelected;

  @override
  Widget build(BuildContext context) {
    final bytes = photoBytes;

    return SizedBox(
      height: 102,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: PhotoFilter.values.map((filter) {
            final isSelected = filter == selectedFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: onSelected == null ? null : () => onSelected!(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 72,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF22C55E)
                          : Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: bytes == null
                              ? const ColoredBox(color: Color(0xFF111111))
                              : filter.colorFilter == null
                                  ? Image.memory(
                                      bytes,
                                      fit: BoxFit.cover,
                                      cacheWidth: 128,
                                      cacheHeight: 128,
                                      gaplessPlayback: false,
                                    )
                                  : ColorFiltered(
                                      colorFilter: filter.colorFilter!,
                                      child: Image.memory(
                                        bytes,
                                        fit: BoxFit.cover,
                                        cacheWidth: 128,
                                        cacheHeight: 128,
                                        gaplessPlayback: false,
                                      ),
                                    ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        filter.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
