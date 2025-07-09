import 'package:flutter/material.dart';
import '../services/location_service.dart';

class DistanceBadge extends StatefulWidget {
  final double? hospitalLatitude;
  final double? hospitalLongitude;
  final String? fallbackText;
  final bool useGoogleMaps;
  
  const DistanceBadge({
    Key? key,
    this.hospitalLatitude,
    this.hospitalLongitude,
    this.fallbackText,
    this.useGoogleMaps = true,
  }) : super(key: key);

  @override
  State<DistanceBadge> createState() => _DistanceBadgeState();
}

class _DistanceBadgeState extends State<DistanceBadge> {
  String _distanceText = '';
  bool _isLoading = false;
  bool _hasError = false;
  bool _isEnableButton = false;

  @override
  void initState() {
    super.initState();
    _loadDistance();
  }

  @override
  void didUpdateWidget(DistanceBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hospitalLatitude != widget.hospitalLatitude ||
        oldWidget.hospitalLongitude != widget.hospitalLongitude) {
      _loadDistance();
    }
  }

  Future<void> _loadDistance() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _isEnableButton = false;
      });
    }

    try {
      // Vérifier si l'hôpital a des coordonnées
      if (widget.hospitalLatitude == null || widget.hospitalLongitude == null) {
        if (mounted) {
          setState(() {
            _distanceText = widget.fallbackText ?? 'Location unavailable';
            _isLoading = false;
            _hasError = true;
          });
        }
        return;
      }

      // Vérifier si la localisation est disponible
      bool locationAvailable = await LocationService.isLocationAvailable();
      if (!locationAvailable) {
        if (mounted) {
          setState(() {
            _distanceText = 'Enable location';
            _isLoading = false;
            _hasError = true;
            _isEnableButton = true;
          });
        }
        return;
      }

      // Calculer la distance
      String distance;
      if (widget.useGoogleMaps) {
        // Utiliser l'API Google Maps pour des calculs plus précis
        distance = await LocationService.getDistanceFromUserWithGoogleMaps(
          widget.hospitalLatitude!,
          widget.hospitalLongitude!,
        );
      } else {
        // Utiliser le calcul géodésique traditionnel
        distance = await LocationService.getDistanceFromUser(
          widget.hospitalLatitude!,
          widget.hospitalLongitude!,
        );
      }

      if (mounted) {
        setState(() {
          _distanceText = distance;
          _isLoading = false;
          _hasError = false;
          _isEnableButton = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _distanceText = widget.fallbackText ?? 'Distance unavailable';
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _enableLocation() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _isEnableButton = false;
      });
    }

    try {
      // Demander les permissions
      bool permissionGranted = await LocationService.checkAndRequestPermission();
      if (!permissionGranted) {
        if (mounted) {
          setState(() {
            _distanceText = 'Permission denied';
            _isLoading = false;
            _hasError = true;
            _isEnableButton = true;
          });
        }
        return;
      }

      // Forcer la détection de la localisation
      final userLocation = await LocationService.forceLocationDetection();
      if (userLocation == null) {
        if (mounted) {
          setState(() {
            _distanceText = 'Location unavailable';
            _isLoading = false;
            _hasError = true;
            _isEnableButton = true;
          });
        }
        return;
      }

      // Calculer la distance avec la nouvelle localisation
      if (widget.hospitalLatitude != null && widget.hospitalLongitude != null) {
        String formattedDistance;
        
        if (widget.useGoogleMaps) {
          // Utiliser l'API Google Maps
          final googleDistance = await LocationService.getDistanceFromGoogleMaps(
            userLocation.latitude,
            userLocation.longitude,
            widget.hospitalLatitude!,
            widget.hospitalLongitude!,
          );
          
          if (googleDistance != null) {
            formattedDistance = '${googleDistance['distance']} (${googleDistance['duration']})';
          } else {
            // Fallback vers le calcul traditionnel
            final distance = LocationService.calculateDistance(
              userLocation.latitude,
              userLocation.longitude,
              widget.hospitalLatitude!,
              widget.hospitalLongitude!,
            );
            formattedDistance = LocationService.formatDistance(distance);
          }
        } else {
          // Calcul géodésique traditionnel
          final distance = LocationService.calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            widget.hospitalLatitude!,
            widget.hospitalLongitude!,
          );
          formattedDistance = LocationService.formatDistance(distance);
        }

        if (mounted) {
          setState(() {
            _distanceText = formattedDistance;
            _isLoading = false;
            _hasError = false;
            _isEnableButton = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _distanceText = 'Error getting location';
          _isLoading = false;
          _hasError = true;
          _isEnableButton = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF159BBD)),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Calculating...',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF159BBD),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_isEnableButton) {
      return GestureDetector(
        onTap: _enableLocation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.orange.shade300, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  size: 12,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Tap to enable',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _hasError ? Colors.red.shade200 : const Color(0xFF159BBD).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _hasError ? Colors.red.shade50 : const Color(0xFF159BBD).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _hasError ? Icons.location_disabled_rounded : Icons.near_me_rounded,
              size: 12,
              color: _hasError ? Colors.red.shade600 : const Color(0xFF159BBD),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _distanceText,
              style: TextStyle(
                fontSize: 12,
                color: _hasError ? Colors.red.shade600 : const Color(0xFF159BBD),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour afficher la distance avec un style plus simple
class SimpleDistanceText extends StatefulWidget {
  final double? hospitalLatitude;
  final double? hospitalLongitude;
  final String? fallbackText;
  final TextStyle? style;

  const SimpleDistanceText({
    Key? key,
    this.hospitalLatitude,
    this.hospitalLongitude,
    this.fallbackText,
    this.style,
  }) : super(key: key);

  @override
  State<SimpleDistanceText> createState() => _SimpleDistanceTextState();
}

class _SimpleDistanceTextState extends State<SimpleDistanceText> {
  String _distanceText = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDistance();
  }

  Future<void> _loadDistance() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (widget.hospitalLatitude == null || widget.hospitalLongitude == null) {
        if (mounted) {
          setState(() {
            _distanceText = widget.fallbackText ?? '';
            _isLoading = false;
          });
        }
        return;
      }

      String distance = await LocationService.getDistanceFromUser(
        widget.hospitalLatitude!,
        widget.hospitalLongitude!,
      );

      if (mounted) {
        setState(() {
          _distanceText = distance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _distanceText = widget.fallbackText ?? '';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Text(
        'Calculating distance...',
        style: widget.style ?? TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (_distanceText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      '$_distanceText from your location',
      style: widget.style ?? TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }
} 