import 'package:flutter/material.dart';
import '../services/location_service.dart';

class DistanceBadge extends StatefulWidget {
  final double? hospitalLatitude;
  final double? hospitalLongitude;
  final String? fallbackText;
  final bool showIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const DistanceBadge({
    Key? key,
    this.hospitalLatitude,
    this.hospitalLongitude,
    this.fallbackText,
    this.showIcon = true,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  }) : super(key: key);

  @override
  State<DistanceBadge> createState() => _DistanceBadgeState();
}

class _DistanceBadgeState extends State<DistanceBadge> {
  String _distanceText = '';
  bool _isLoading = true;
  bool _hasError = false;
  bool _isEnableButton = false;

  @override
  void initState() {
    super.initState();
    _loadDistance();
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
      String distance = await LocationService.getDistanceFromUser(
        widget.hospitalLatitude!,
        widget.hospitalLongitude!,
      );

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
        final distance = LocationService.calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          widget.hospitalLatitude!,
          widget.hospitalLongitude!,
        );

        final formattedDistance = LocationService.formatDistance(distance);

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
    return GestureDetector(
      onTap: _isEnableButton ? _enableLocation : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showIcon && !_isLoading && !_hasError) ...[
              Icon(
                Icons.location_on,
                size: 12,
                color: _getTextColor(),
              ),
              const SizedBox(width: 4),
            ],
            if (_isLoading) ...[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Calculating...',
                style: TextStyle(
                  fontSize: widget.fontSize ?? 10,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(),
                ),
              ),
            ] else ...[
              Flexible(
                child: Text(
                  _distanceText,
                  style: TextStyle(
                    fontSize: widget.fontSize ?? 10,
                    fontWeight: FontWeight.w500,
                    color: _getTextColor(),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.backgroundColor != null) {
      return widget.backgroundColor!;
    }
    
    if (_hasError) {
      return _isEnableButton ? Colors.blue[50]! : Colors.grey[100]!;
    }
    
    if (_isLoading) {
      return const Color(0xFF159BBD).withOpacity(0.1);
    }
    
    return const Color(0xFF159BBD).withOpacity(0.1);
  }

  Color _getTextColor() {
    if (widget.textColor != null) {
      return widget.textColor!;
    }
    
    if (_hasError) {
      return _isEnableButton ? Colors.blue[600]! : Colors.grey[600]!;
    }
    
    if (_isLoading) {
      return const Color(0xFF159BBD);
    }
    
    return const Color(0xFF159BBD);
  }

  Color _getBorderColor() {
    if (_hasError) {
      return _isEnableButton ? Colors.blue[300]! : Colors.grey[300]!;
    }
    
    if (_isLoading) {
      return const Color(0xFF159BBD).withOpacity(0.3);
    }
    
    return const Color(0xFF159BBD).withOpacity(0.3);
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