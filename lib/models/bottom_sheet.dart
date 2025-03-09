import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer package

class LocationBottomSheet extends StatefulWidget {
  @override
  _LocationBottomSheetState createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  double _dragPosition = 0.0; // Tracks the position of the swipe
  bool _isPunchedIn = false; // Tracks if the user has punched in

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxWidth) {
    setState(() {
      // Update drag position based on the swipe
      _dragPosition += details.delta.dx;

      // Clamp the position so the circle doesn't move outside the container
      if (_dragPosition < 0) _dragPosition = 0;
      if (_dragPosition > maxWidth) _dragPosition = maxWidth;
    });
  }

  void _onHorizontalDragEnd(double maxWidth) {
    // If the swipe is more than halfway, trigger punch-in
    if (_dragPosition >= maxWidth / 2 && !_isPunchedIn) {
      setState(() {
        _isPunchedIn = true;
        _dragPosition = maxWidth; // Snap to the end
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Punched In!')),
      );
    } else {
      // If not swiped far enough, reset to the start
      setState(() {
        _dragPosition = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the maximum width the circular button can travel
    double maxWidth = MediaQuery.of(context).size.width - 32 - 65; // Screen width - padding - button width

    return Scaffold(
      appBar: AppBar(
        title: Text('Punch In'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Placeholder
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                child: Icon(
                  Icons.business,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              // Company Name and Address
              Text(
                'Space Infotech Pvt. Ltd.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '4 Donnerville Hall, Donnerville Drive,',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.check_circle, color: Colors.green, size: 16), // Verified checkmark
                ],
              ),
              Text(
                'Admastor, TFS 0DF',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 40),
              // Custom Swipe to Punch In Button with Conditional Shimmer
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Shimmer effect applied only when not punched in
                  if (!_isPunchedIn)
                    Shimmer.fromColors(
                      baseColor: Colors.green[700]!,
                      highlightColor: Colors.white,
                      period: Duration(milliseconds: 1500),
                      child: Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  // The circular button that can be dragged
                  Positioned(
                    left: _dragPosition,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        _onHorizontalDragUpdate(details, maxWidth);
                      },
                      onHorizontalDragEnd: (details) {
                        _onHorizontalDragEnd(maxWidth);
                      },
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  // Center the "Swipe right to Punch In" text on top of the shimmer
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        _isPunchedIn ? 'Punched In!' : 'Swipe right to Punch In',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}