import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_screen_provider.dart';

class LocationBottomSheet extends StatefulWidget {
  final bool isCheckIn;

  const LocationBottomSheet({
    super.key,
    required this.isCheckIn,
  });

  @override
  _LocationBottomSheetState createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  double _dragPosition = 0.0;
  bool _isActionCompleted = false;
  String _currentAddress = "Fetching location...";
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentAddress = "Location services are disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentAddress = "Location permissions denied.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _currentAddress = "Location permissions permanently denied.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = position);
      await _getAddressFromLatLng(position);
    } catch (e) {
      setState(() => _currentAddress = "Failed to get location: $e");
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
        });
      }
    } catch (e) {
      setState(() => _currentAddress = "Failed to get address: $e");
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (_isActionCompleted || _currentPosition == null) return;
    setState(() {
      _dragPosition += details.delta.dx;
      _dragPosition = _dragPosition.clamp(0.0, maxWidth);
    });
  }

  void _onHorizontalDragEnd(BuildContext context, double maxWidth) async {
    if (_isActionCompleted || _currentPosition == null) return;

    if (_dragPosition >= maxWidth / 2) {
      setState(() => _isActionCompleted = true);
      
      try {
        final provider = Provider.of<AttendanceScreenProvider>(context, listen: false);
        DateTime actionTime = DateTime.now();

        if (widget.isCheckIn) {
          print("Executing check-in via provider");
          await provider.handleCheckIn(actionTime);
        } else {
          print("Executing check-out via provider");
          await provider.handleCheckOut(actionTime);
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isCheckIn ? 'Successfully checked in!' : 'Successfully checked out!'),
              backgroundColor: widget.isCheckIn ? Colors.green : Colors.red,
            ),
          );
        }

        // Delay pop to show completion state
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        print("Error during ${widget.isCheckIn ? 'check-in' : 'check-out'}: $e");
        setState(() => _isActionCompleted = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ${widget.isCheckIn ? 'check in' : 'check out'}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() => _dragPosition = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    double maxWidth = MediaQuery.of(context).size.width - 32 - 65;

    return WillPopScope(
      onWillPop: () async {
        return !_isActionCompleted;
      },
      child: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.business, size: 20, color: Colors.white),
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Space Infotech Pvt. Ltd.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              _currentAddress,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            _buildSlider(context, maxWidth),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(BuildContext context, double maxWidth) {
    final baseColor = widget.isCheckIn ? Colors.green : Colors.red;
    final shimmerBaseColor = widget.isCheckIn ? Colors.green[300]! : Colors.red[300]!;
    final shimmerHighlightColor = widget.isCheckIn ? Colors.green[100]! : Colors.red[100]!;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        _currentPosition == null
            ? Shimmer.fromColors(
                baseColor: shimmerBaseColor,
                highlightColor: shimmerHighlightColor,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(_isActionCompleted ? 0.7 : 1.0),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
        if (!_isActionCompleted)
          Positioned(
            left: _dragPosition,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, maxWidth),
              onHorizontalDragEnd: (details) => _onHorizontalDragEnd(context, maxWidth),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: baseColor,
                  size: 20,
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: Center(
            child: Text(
              _isActionCompleted
                  ? (widget.isCheckIn ? 'Checked In!' : 'Checked Out!')
                  : (widget.isCheckIn ? 'Swipe to Check In' : 'Swipe to Check Out'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}