import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';

/// Ilustrasi hero khusus pada header `AdminDashboardScreen`.
class DashboardHeroIllustration extends StatelessWidget {
  final double height;

  const DashboardHeroIllustration({
    super.key,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Kartu statistik
          Positioned(
            right: 3,
            top: 4,
            child: Container(
              width: 112,
              height: height * 0.82,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFD8E7FF),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33002374),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      _IllustrationDot(color: Color(0xFFFF7777)),
                      SizedBox(width: 4),
                      _IllustrationDot(color: Color(0xFFFFC34D)),
                      SizedBox(width: 4),
                      _IllustrationDot(color: Color(0xFF5ACB9B)),
                      Spacer(),
                      Icon(
                        Icons.more_horiz_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Laporan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _IllustrationBar(
                          height: 25,
                          color: Color(0xFF8EBBFF),
                        ),
                        _IllustrationBar(
                          height: 38,
                          color: Color(0xFF438DFF),
                        ),
                        _IllustrationBar(
                          height: 31,
                          color: Color(0xFF65A5FF),
                        ),
                        _IllustrationBar(
                          height: 46,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7EEF8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ilustrasi admin
          Positioned(
            left: 0,
            bottom: 5,
            child: Container(
              width: 67,
              height: height * 0.62,
              decoration: BoxDecoration(
                color: const Color(0xFFB9DAFF),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 53,
                color: Color(0xFF1767D8),
              ),
            ),
          ),

          // Laptop
          Positioned(
            left: 12,
            bottom: 0,
            child: Container(
              width: 88,
              height: 15,
              decoration: BoxDecoration(
                color: const Color(0xFF274E85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.laptop_mac_rounded,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),

          // Aksen
          const Positioned(
            right: 0,
            top: 0,
            child: Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFFFC12F),
              size: 25,
            ),
          ),
          const Positioned(
            left: 0,
            top: 18,
            child: Icon(
              Icons.cloud_rounded,
              color: Color(0xFFB9D9FF),
              size: 23,
            ),
          ),
          const Positioned(
            right: 0,
            bottom: 18,
            child: Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF9FD5FF),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationDot extends StatelessWidget {
  final Color color;

  const _IllustrationDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _IllustrationBar extends StatelessWidget {
  final double height;
  final Color color;

  const _IllustrationBar({
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}
