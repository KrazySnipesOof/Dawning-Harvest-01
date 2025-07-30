import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:typed_data';

// Global state for managing farm fields
class FieldState extends ChangeNotifier {
  List<Map<String, dynamic>> _fields = [];
  String? _selectedFieldId;

  List<Map<String, dynamic>> get fields => _fields;
  String? get selectedFieldId => _selectedFieldId;

  void addField(Map<String, dynamic> field) {
    _fields.add(field);
    notifyListeners();
  }

  void updateField({
    required String fieldId,
    required String name,
    required String crop,
    String? harvestDate,
    required bool needsWatering,
    required int growthPercentage,
    required Color color,
  }) {
    final fieldIndex = _fields.indexWhere((f) => f['id'] == fieldId);
    if (fieldIndex != -1) {
      _fields[fieldIndex].addAll({
        'name': name,
        'crop': crop,
        'harvestDate': harvestDate,
        'needsWatering': needsWatering,
        'growthPercentage': growthPercentage,
        'color': color.value,
      });
      notifyListeners();
    }
  }

  void deleteField(String fieldId) {
    _fields.removeWhere((f) => f['id'] == fieldId);
    if (_selectedFieldId == fieldId) {
      _selectedFieldId = null;
    }
    notifyListeners();
  }

  void selectField(String? fieldId) {
    _selectedFieldId = fieldId;
    notifyListeners();
  }

  void toggleIrrigation(String fieldId) {
    final fieldIndex = _fields.indexWhere((f) => f['id'] == fieldId);
    if (fieldIndex != -1) {
      _fields[fieldIndex]['needsWatering'] = !(_fields[fieldIndex]['needsWatering'] ?? false);
      notifyListeners();
    }
  }

  Map<String, dynamic>? getFieldById(String fieldId) {
    try {
      return _fields.firstWhere((f) => f['id'] == fieldId);
    } catch (e) {
      return null;
    }
  }
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileState()),
        ChangeNotifierProvider(create: (_) => FieldState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dawning Harvest',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green,
          inversePrimary: Colors.green.shade100,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const MapPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.green,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
            backgroundColor: Colors.green,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
            backgroundColor: Colors.green,
          ),
        ],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.shifting,
        elevation: 8,
        showUnselectedLabels: true,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Helper methods for location-based weather data
  String _getTemperatureForLocation(String city) {
    // Simulate location-based temperature in Fahrenheit
    Map<String, int> cityTemperatures = {
      'Farmville': 84,
      'New York': 72,
      'Los Angeles': 78,
      'Chicago': 68,
      'Miami': 88,
      'Seattle': 65,
      'Denver': 70,
      'Phoenix': 95,
      'Boston': 69,
      'San Francisco': 62,
    };
    return cityTemperatures[city]?.toString() ?? '75';
  }

  String _getRoomTemperature(String city) {
    // Room temperature is typically 5-10 degrees cooler than outside
    int outsideTemp = int.parse(_getTemperatureForLocation(city));
    return (outsideTemp - 7).toString();
  }

  String _getSunlightHours(String city) {
    // Simulate sunlight hours based on location
    Map<String, String> citySunlight = {
      'Farmville': '10.2 hours',
      'New York': '9.8 hours',
      'Los Angeles': '11.5 hours',
      'Chicago': '9.3 hours',
      'Miami': '11.8 hours',
      'Seattle': '8.2 hours',
      'Denver': '10.5 hours',
      'Phoenix': '12.1 hours',
      'Boston': '9.5 hours',
      'San Francisco': '10.0 hours',
    };
    return citySunlight[city] ?? '9.5 hours';
  }

  String _getWindSpeed(String city) {
    // Simulate wind speed in mph
    Map<String, int> cityWindSpeed = {
      'Farmville': 8,
      'New York': 12,
      'Los Angeles': 6,
      'Chicago': 15,
      'Miami': 10,
      'Seattle': 9,
      'Denver': 11,
      'Phoenix': 5,
      'Boston': 13,
      'San Francisco': 14,
    };
    return cityWindSpeed[city]?.toString() ?? '8';
  }

  String _getHumidity(String city) {
    // Simulate humidity percentage
    Map<String, int> cityHumidity = {
      'Farmville': 68,
      'New York': 65,
      'Los Angeles': 45,
      'Chicago': 72,
      'Miami': 85,
      'Seattle': 78,
      'Denver': 35,
      'Phoenix': 25,
      'Boston': 70,
      'San Francisco': 55,
    };
    return cityHumidity[city]?.toString() ?? '65';
  }

  String _getPressure(String city) {
    // Simulate atmospheric pressure in inches of mercury
    Map<String, String> cityPressure = {
      'Farmville': '30.15',
      'New York': '30.12',
      'Los Angeles': '30.18',
      'Chicago': '30.08',
      'Miami': '30.20',
      'Seattle': '30.05',
      'Denver': '24.85', // Higher altitude = lower pressure
      'Phoenix': '29.95',
      'Boston': '30.10',
      'San Francisco': '30.14',
    };
    return cityPressure[city] ?? '30.12';
  }

  @override
  Widget build(BuildContext context) {
    final profileState = Provider.of<ProfileState>(context);
    final fieldState = Provider.of<FieldState>(context);
    final firstName = profileState.accountDetails['First Name'] ?? '';
    final imageFile = profileState.imageFile;
    final location = profileState.locationDisplay;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/harvest_logo.png',
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text('HARVEST'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: imageFile != null
                      ? kIsWeb
                          ? NetworkImage(imageFile.path)
                          : FileImage(File(imageFile.path)) as ImageProvider
                      : null,
                  child: imageFile == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Weather in ${profileState.shippingAddress['City'] ?? 'Your Location'}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              Icon(
                                Icons.wb_sunny,
                                color: Colors.orange.shade600,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE').format(DateTime.now()),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '(${DateFormat('MMM').format(DateTime.now())}, ${DateTime.now().year})',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Text(
                                        _getTemperatureForLocation(profileState.shippingAddress['City'] ?? ''),
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        '°F',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _getSunlightHours(profileState.shippingAddress['City'] ?? ''),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: Stack(
                                  children: [
                                    CircularProgressIndicator(
                                      value: 0.86,
                                      strokeWidth: 10,
                                      backgroundColor: Colors.green.withOpacity(0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green.shade700,
                                      ),
                                    ),
                                    Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${_getRoomTemperature(profileState.shippingAddress['City'] ?? '')}°F',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text(
                                            'Room temp',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.air),
                                  Text('${_getWindSpeed(profileState.shippingAddress['City'] ?? '')} mph'),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(Icons.water_drop),
                                  Text('${_getHumidity(profileState.shippingAddress['City'] ?? '')}%'),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(Icons.compress),
                                  Text('${_getPressure(profileState.shippingAddress['City'] ?? '')} inHg'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Plant growth activity',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  children: [
                                    Text('Weekly'),
                                    Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 150,
                            child: CustomPaint(
                              size: const Size(double.infinity, 150),
                              painter: GrowthLinePainter(),
                            ),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Icon(Icons.spa, color: Colors.white),
                                  ),
                                  Text('Seed Phase'),
                                  Text('(W1)', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                              Column(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Icon(Icons.eco, color: Colors.white),
                                  ),
                                  Text('Final Growth'),
                                  Text('(W2)', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                              Column(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Icon(Icons.forest, color: Colors.white),
                                  ),
                                  Text('Vegetation'),
                                  Text('(W3)', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'My Fields',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${fieldState.fields.length} fields',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 200,
                            child: fieldState.fields.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.agriculture_outlined,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'No fields yet',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Go to Map to create',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: fieldState.fields.length,
                                    itemBuilder: (context, index) {
                                      final field = fieldState.fields[index];
                                      final fieldColor = Color(field['color'] ?? Colors.green.value);
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: fieldColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: fieldColor.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: fieldColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    field['name'] ?? 'Unnamed Field',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    field['crop'] ?? 'Unknown',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (field['needsWatering'] == true)
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Icon(
                                                  Icons.water_drop,
                                                  size: 12,
                                                  color: Colors.blue.shade700,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Summary of production',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.filter_list),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.fullscreen),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: CustomPaint(
                        size: const Size(double.infinity, 300),
                        painter: ProductionChartPainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.green.shade700,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileState.shippingAddress['City'] ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Located in ${profileState.shippingAddress['State'] ?? ''}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          Slider(
                            value: 0.5,
                            onChanged: (value) {},
                            activeColor: Colors.white,
                            inactiveColor: Colors.white24,
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '18.90',
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                '36.00',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Image.asset(
                      'assets/images/vertical_farming.png',
                      height: 200,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 48,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GrowthLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.2,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.8,
        size.width,
        size.height * 0.3,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProductionChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.1, size.height * 0.7)
      ..lineTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.3, size.height * 0.6)
      ..lineTo(size.width * 0.4, size.height * 0.4)
      ..lineTo(size.width * 0.5, size.height * 0.3)
      ..lineTo(size.width * 0.6, size.height * 0.5)
      ..lineTo(size.width * 0.7, size.height * 0.2)
      ..lineTo(size.width * 0.8, size.height * 0.4)
      ..lineTo(size.width * 0.9, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _controller;
  
  // Default location (Farmville, CA coordinates) - fallback if location fails
  static const LatLng _defaultLocation = LatLng(37.4419, -122.1430);
  
  // User's current location
  LatLng? _userLocation;
  bool _locationLoading = true;
  String _locationError = '';
  
  // Drawing state
  bool _isDrawingMode = false;
  List<LatLng> _currentPolygonPoints = [];
  Set<Polygon> _drawnFarms = {};
  
  // Farm management
  List<Map<String, dynamic>> _savedFarms = [];
  
  // Sample farming locations
  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('farm1'),
      position: LatLng(37.4419, -122.1430),
      infoWindow: InfoWindow(
        title: 'Green Valley Farm',
        snippet: 'Organic vegetables and fruits',
      ),
    ),
    const Marker(
      markerId: MarkerId('farm2'),
      position: LatLng(37.4519, -122.1530),
      infoWindow: InfoWindow(
        title: 'Sunshine Orchards',
        snippet: 'Fresh citrus and stone fruits',
      ),
    ),
    const Marker(
      markerId: MarkerId('farm3'),
      position: LatLng(37.4319, -122.1330),
      infoWindow: InfoWindow(
        title: 'Heritage Farms',
        snippet: 'Sustainable farming practices',
      ),
    ),
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _locationLoading = true;
        _locationError = '';
      });

      // For web, we need to use the HTML5 Geolocation API
      if (kIsWeb) {
        await _getWebLocation();
      } else {
        // For mobile apps, you would use location packages like geolocator
        // For now, fallback to default location
        setState(() {
          _userLocation = _defaultLocation;
          _locationLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Could not get location: $e';
        _userLocation = _defaultLocation;
        _locationLoading = false;
      });
    }
  }

  Future<void> _getWebLocation() async {
    // Using dart:html for web geolocation
    try {
      final position = await _requestWebLocation();
      if (position != null) {
        final lat = position['latitude'];
        final lng = position['longitude'];
        if (lat != null && lng != null) {
          setState(() {
            _userLocation = LatLng(lat, lng);
            _locationLoading = false;
          });
        } else {
          throw Exception('Invalid coordinates received');
        }
        
        // Update camera to user location
        if (_controller != null) {
          _controller!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _userLocation!,
                zoom: 15.0,
              ),
            ),
          );
        }
      } else {
        throw Exception('Location permission denied or unavailable');
      }
    } catch (e) {
      setState(() {
        _locationError = 'Location access denied or unavailable';
        _userLocation = _defaultLocation;
        _locationLoading = false;
      });
    }
  }

    Future<Map<String, double>?> _requestWebLocation() async {
    if (!kIsWeb) return null;
    
    try {
      final completer = Completer<Map<String, double>?>();
      
      // Check if geolocation is available
      if (html.window.navigator.geolocation == null) {
        completer.complete(null);
        return completer.future;
      }
      
      // Request current position
      html.window.navigator.geolocation!.getCurrentPosition().then((position) {
        final coords = position.coords!;
        completer.complete({
          'latitude': coords.latitude!.toDouble(),
          'longitude': coords.longitude!.toDouble(),
        });
      }).catchError((error) {
        print('Geolocation error: $error');
        completer.complete(null);
      });
      
      return completer.future;
    } catch (e) {
      print('Web geolocation error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = Provider.of<ProfileState>(context);
    final fieldState = Provider.of<FieldState>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isDrawingMode ? 'Draw Field Boundary' : 'Farm Fields Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isDrawingMode) ...[
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undoLastPoint,
              tooltip: 'Undo last point',
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _completeFieldDrawing,
              tooltip: 'Complete field',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelDrawing,
              tooltip: 'Cancel drawing',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _goToUserLocation,
              tooltip: 'Go to my location',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _getCurrentLocation,
              tooltip: 'Refresh location',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: _isDrawingMode ? Colors.orange.shade50 : Colors.green.shade50,
                child: Row(
                  children: [
                    Icon(
                      _isDrawingMode ? Icons.edit_location : Icons.agriculture, 
                      color: _isDrawingMode ? Colors.orange.shade700 : Colors.green.shade700
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isDrawingMode 
                            ? 'Tap points to outline field boundary (${_currentPolygonPoints.length} points)'
                            : _locationLoading
                                ? 'Getting your location...'
                                : _locationError.isNotEmpty
                                    ? _locationError
                                    : 'Tap a field to manage crops and irrigation',
                        style: TextStyle(
                          color: _isDrawingMode ? Colors.orange.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_locationLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isDrawingMode ? Colors.orange.shade700 : Colors.green.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _controller = controller;
                        if (_userLocation != null && !_locationLoading) {
                          _controller!.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: _userLocation!,
                                zoom: 15.0,
                              ),
                            ),
                          );
                        }
                      },
                      onTap: _isDrawingMode ? _onMapTapped : _onFieldTapped,
                      initialCameraPosition: CameraPosition(
                        target: _userLocation ?? _defaultLocation,
                        zoom: _userLocation != null ? 15.0 : 12.0,
                      ),
                      markers: _getAllMarkers(),
                      polygons: _getFieldPolygons().union(_getCurrentPolygonSet()).union(_getDrawingPointCircles()),
                      polylines: _getCurrentPolylineSet(),
                      mapType: MapType.satellite,
                      zoomControlsEnabled: true,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      compassEnabled: true,
                      mapToolbarEnabled: false,
                    ),
                    // Field name overlays
                    ..._buildFieldNameOverlays(),
                  ],
                ),
              ),
            ],
          ),
          // Field details overlay
          if (fieldState.selectedFieldId != null) _buildFieldDetailsOverlay(),
          // Bottom action buttons
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                if (!_isDrawingMode) ...[
                  FloatingActionButton(
                    heroTag: "add_field",
                    onPressed: _toggleDrawingMode,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.add_location_alt),
                  ),
                  const SizedBox(height: 12),
                ],
                FloatingActionButton(
                  heroTag: "fields_list",
                  onPressed: _showFieldsList,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.agriculture),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Set<Polygon> _getFieldPolygons() {
    final fieldState = Provider.of<FieldState>(context, listen: false);
    return fieldState.fields.map((field) {
      final points = (field['points'] as List).map((point) => 
        LatLng(point['lat'], point['lng'])
      ).toList();
      
      final isSelected = field['id'] == fieldState.selectedFieldId;
      final fieldColor = Color(field['color'] ?? Colors.green.value);
      
      return Polygon(
        polygonId: PolygonId(field['id']),
        points: points,
        strokeColor: isSelected ? Colors.blue : fieldColor,
        strokeWidth: isSelected ? 3 : 2,
        fillColor: (isSelected ? Colors.blue : fieldColor).withOpacity(0.3),
        consumeTapEvents: true,
      );
    }).toSet();
  }

  void _onFieldTapped(LatLng point) {
    final fieldState = Provider.of<FieldState>(context, listen: false);
    // Check if tap is inside any field
    for (int i = 0; i < fieldState.fields.length; i++) {
      final field = fieldState.fields[i];
      final points = (field['points'] as List).map((p) => 
        LatLng(p['lat'], p['lng'])
      ).toList();
      
      if (_isPointInPolygon(point, points)) {
        _showFieldBottomSheet(field, i);
        return;
      }
    }
    
    // If no field was tapped, deselect
    fieldState.selectField(null);
  }

  void _showFieldBottomSheet(Map<String, dynamic> field, int fieldIndex) {
    final fieldColor = Color(field['color'] ?? Colors.green.value);
    final cropName = field['crop'] ?? 'Unknown Crop';
    final isWatered = field['needsWatering'] != true;
    final growthPercentage = field['growthPercentage'] ?? 50;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cropName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isWatered ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isWatered ? Icons.water_drop : Icons.water_drop_outlined,
                          size: 16,
                          color: isWatered ? Colors.blue : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isWatered ? 'Well Watered' : 'Needs Water',
                          style: TextStyle(
                            color: isWatered ? Colors.blue : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$growthPercentage%',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleFieldWatering(fieldIndex);
                      },
                      icon: Icon(
                        isWatered ? Icons.water_drop : Icons.water_drop_outlined,
                        color: Colors.white,
                      ),
                      label: Text(
                        isWatered ? 'Watered' : 'Water',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isWatered ? Colors.blue : Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editField(field['id'] as String);
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Edit',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _toggleFieldWatering(int fieldIndex) {
    final fieldState = Provider.of<FieldState>(context, listen: false);
    final field = fieldState.fields[fieldIndex];
    final fieldId = field['id'] as String;
    
    fieldState.toggleIrrigation(fieldId);
    
    final newWateringStatus = !(field['needsWatering'] != true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newWateringStatus 
            ? 'Field marked as needing water' 
            : 'Field marked as well watered',
        ),
        backgroundColor: newWateringStatus ? Colors.orange : Colors.blue,
      ),
    );
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    // Simple point-in-polygon test using ray casting algorithm
    int intersections = 0;
    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;
      
      if ((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) {
        double intersectLng = (polygon[j].longitude - polygon[i].longitude) * 
                             (point.latitude - polygon[i].latitude) / 
                             (polygon[j].latitude - polygon[i].latitude) + 
                             polygon[i].longitude;
        
        if (point.longitude < intersectLng) {
          intersections++;
        }
      }
    }
    return intersections % 2 == 1;
  }

  Widget _buildFieldDetailsOverlay() {
    final fieldState = Provider.of<FieldState>(context, listen: false);
    final field = fieldState.getFieldById(fieldState.selectedFieldId!);
    if (field == null) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 120,
      left: 20,
      right: 20,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    field['crop'] ?? 'Field',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => fieldState.selectField(null),
                  ),
                ],
              ),
              if (field['harvestDate'] != null)
                Text(
                  'Harvest on ${field['harvestDate']}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatusChip(
                    icon: Icons.water_drop,
                    label: field['needsWatering'] == true ? 'Need Watering' : 'Well Watered',
                    color: field['needsWatering'] == true ? Colors.orange : Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildStatusChip(
                    icon: Icons.trending_up,
                    label: '${field['growthPercentage'] ?? 74}%',
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleIrrigation(field['id']),
                      icon: Icon(
                        field['needsWatering'] == true ? Icons.water_drop : Icons.check_circle,
                        size: 18,
                      ),
                      label: Text(field['needsWatering'] == true ? 'Water Now' : 'Watered'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: field['needsWatering'] == true ? Colors.blue : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _editField(field['id']),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _completeFieldDrawing() {
    if (_currentPolygonPoints.length >= 3) {
      _showFieldCreationDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 3 points to create a field boundary'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showFieldCreationDialog() {
    String fieldName = '';
    String cropType = 'Wheat';
    String harvestDate = '';
    bool needsWatering = false;
    int growthPercentage = 74;

    // Create controllers for text fields
    final TextEditingController fieldNameController = TextEditingController();
    final TextEditingController harvestDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Field'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fieldNameController,
                  decoration: const InputDecoration(
                    labelText: 'Field Name',
                    hintText: 'e.g., North Field',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => fieldName = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: cropType,
                  decoration: const InputDecoration(
                    labelText: 'Crop Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Wheat', 'Corn', 'Soybeans', 'Rice', 'Barley', 'Oats']
                      .map((crop) => DropdownMenuItem(value: crop, child: Text(crop)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => cropType = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: harvestDateController,
                  decoration: const InputDecoration(
                    labelText: 'Harvest Date',
                    hintText: 'e.g., May 01, 2024',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => harvestDate = value,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Needs Watering'),
                  value: needsWatering,
                  onChanged: (value) => setDialogState(() => needsWatering = value!),
                ),
                const SizedBox(height: 16),
                Text('Growth Progress: $growthPercentage%'),
                Slider(
                  value: growthPercentage.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  onChanged: (value) => setDialogState(() => growthPercentage = value.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                fieldNameController.dispose();
                harvestDateController.dispose();
                _cancelDrawing();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final fieldState = Provider.of<FieldState>(context, listen: false);
                final finalFieldName = fieldNameController.text.isEmpty 
                    ? 'Field ${fieldState.fields.length + 1}' 
                    : fieldNameController.text;
                final finalHarvestDate = harvestDateController.text.isEmpty 
                    ? null 
                    : harvestDateController.text;
                
                _createField(
                  name: finalFieldName,
                  crop: cropType,
                  harvestDate: finalHarvestDate,
                  needsWatering: needsWatering,
                  growthPercentage: growthPercentage,
                );
                
                fieldNameController.dispose();
                harvestDateController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Create Field'),
            ),
          ],
        ),
      ),
    );
  }

  void _createField({
    required String name,
    required String crop,
    String? harvestDate,
    required bool needsWatering,
    required int growthPercentage,
  }) {
    final fieldState = Provider.of<FieldState>(context, listen: false);
    final fieldId = 'field_${DateTime.now().millisecondsSinceEpoch}';
    
    final fieldData = {
      'id': fieldId,
      'name': name,
      'crop': crop,
      'harvestDate': harvestDate,
      'needsWatering': needsWatering,
      'growthPercentage': growthPercentage,
      'color': Colors.green.value, // Default field color
      'points': _currentPolygonPoints.map((point) => {
        'lat': point.latitude,
        'lng': point.longitude,
      }).toList(),
      'area': _calculateArea(_currentPolygonPoints).toStringAsFixed(1),
      'dateCreated': DateTime.now().toIso8601String(),
    };

    fieldState.addField(fieldData);
    fieldState.selectField(fieldId);
    
    setState(() {
      _currentPolygonPoints.clear();
      _isDrawingMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Field "$name" created successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleIrrigation(String fieldId) {
    final fieldState = Provider.of<FieldState>(context, listen: false);
    fieldState.toggleIrrigation(fieldId);
    
    final field = fieldState.getFieldById(fieldId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(field?['needsWatering'] == true
            ? 'Irrigation scheduled' : 'Irrigation completed'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editField(String fieldId) {
    final fieldState = Provider.of<FieldState>(context, listen: false);
    final field = fieldState.getFieldById(fieldId);
    if (field != null) {
      _showFieldEditDialog(field);
    }
  }

  void _showFieldEditDialog(Map<String, dynamic> field) {
    String fieldName = field['name'] ?? '';
    String cropType = field['crop'] ?? 'Wheat';
    String harvestDate = field['harvestDate'] ?? '';
    bool needsWatering = field['needsWatering'] ?? false;
    int growthPercentage = field['growthPercentage'] ?? 74;
    Color fieldColor = Color(field['color'] ?? Colors.green.value);

    // Create controllers for text fields with initial values
    final TextEditingController fieldNameController = TextEditingController(text: fieldName);
    final TextEditingController harvestDateController = TextEditingController(text: harvestDate);
    
    // Create focus nodes for better input handling
    final FocusNode fieldNameFocusNode = FocusNode();
    final FocusNode harvestDateFocusNode = FocusNode();

    // Predefined color options
    final List<Color> colorOptions = [
      Colors.green,
      Colors.blue,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Field'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fieldNameController,
                  focusNode: fieldNameFocusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Field Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => fieldName = value,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => harvestDateFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: cropType,
                  decoration: const InputDecoration(
                    labelText: 'Crop Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Wheat', 'Corn', 'Soybeans', 'Rice', 'Barley', 'Oats']
                      .map((crop) => DropdownMenuItem(value: crop, child: Text(crop)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => cropType = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: harvestDateController,
                  focusNode: harvestDateFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Harvest Date',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., July 2024',
                  ),
                  onChanged: (value) => harvestDate = value,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                // Field Color Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Field Color',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 60,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: colorOptions.length,
                        itemBuilder: (context, index) {
                          final color = colorOptions[index];
                          final isSelected = fieldColor.value == color.value;
                          
                          return GestureDetector(
                            onTap: () => setDialogState(() => fieldColor = color),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.grey.shade300,
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ] : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Needs Watering'),
                  value: needsWatering,
                  onChanged: (value) => setDialogState(() => needsWatering = value!),
                ),
                const SizedBox(height: 16),
                Text('Growth Progress: $growthPercentage%'),
                Slider(
                  value: growthPercentage.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  onChanged: (value) => setDialogState(() => growthPercentage = value.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                fieldNameController.dispose();
                harvestDateController.dispose();
                fieldNameFocusNode.dispose();
                harvestDateFocusNode.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                fieldNameController.dispose();
                harvestDateController.dispose();
                fieldNameFocusNode.dispose();
                harvestDateFocusNode.dispose();
                _deleteField(field['id']);
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                final finalFieldName = fieldNameController.text.isEmpty 
                    ? 'Unnamed Field' 
                    : fieldNameController.text;
                final finalHarvestDate = harvestDateController.text.isEmpty 
                    ? null 
                    : harvestDateController.text;
                
                _updateField(
                  fieldId: field['id'],
                  name: finalFieldName,
                  crop: cropType,
                  harvestDate: finalHarvestDate,
                  needsWatering: needsWatering,
                  growthPercentage: growthPercentage,
                  color: fieldColor,
                );
                
                fieldNameController.dispose();
                harvestDateController.dispose();
                fieldNameFocusNode.dispose();
                harvestDateFocusNode.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateField({
    required String fieldId,
    required String name,
    required String crop,
    String? harvestDate,
    required bool needsWatering,
    required int growthPercentage,
    required Color color,
  }) {
    final fieldState = Provider.of<FieldState>(context, listen: false);
    fieldState.updateField(
      fieldId: fieldId,
      name: name,
      crop: crop,
      harvestDate: harvestDate,
      needsWatering: needsWatering,
      growthPercentage: growthPercentage,
      color: color,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Field "$name" updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteField(String fieldId) {
    final fieldState = Provider.of<FieldState>(context, listen: false);
    fieldState.deleteField(fieldId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Field deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showFieldsList() {
    final fieldState = Provider.of<FieldState>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Fields',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.pop(context);
                    _toggleDrawingMode();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (fieldState.fields.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.agriculture_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No fields yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Draw your first field!', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: fieldState.fields.length,
                  itemBuilder: (context, index) {
                    final field = fieldState.fields[index];
                    final fieldColor = Color(field['color'] ?? Colors.green.value);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: fieldColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                        ),
                        title: Text(field['name'] ?? 'Unnamed Field'),
                        subtitle: Text('${field['crop']} • ${field['area']} acres'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (field['needsWatering'] == true)
                              Icon(Icons.water_drop, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text('${field['growthPercentage'] ?? 74}%'),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          fieldState.selectField(field['id']);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

     void _focusOnField(Map<String, dynamic> field) {
     final points = (field['points'] as List).map((point) => 
       LatLng(point['lat'], point['lng'])
     ).toList();

     if (_controller != null && points.isNotEmpty) {
       _controller!.animateCamera(
         CameraUpdate.newLatLngBounds(
           _getBoundsFromPoints(points),
           100.0,
         ),
       );
     }
   }

   Set<Polygon> _getCurrentPolygonSet() {
     if (_currentPolygonPoints.isEmpty) return {};
     
     return {
       Polygon(
         polygonId: const PolygonId('current_drawing'),
         points: _currentPolygonPoints,
         strokeColor: Colors.orange,
         strokeWidth: 3,
         fillColor: Colors.orange.withOpacity(0.3),
       ),
     };
   }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (!_isDrawingMode) {
        _currentPolygonPoints.clear();
      }
    });
  }

  void _onMapTapped(LatLng point) {
    if (!_isDrawingMode) return;
    
    setState(() {
      _currentPolygonPoints.add(point);
    });
    
    // Show a brief snackbar with point info
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Point ${_currentPolygonPoints.length} added at ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _undoLastPoint() {
    if (_currentPolygonPoints.isNotEmpty) {
      setState(() {
        _currentPolygonPoints.removeLast();
      });
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentPolygonPoints.isEmpty 
                ? 'All points removed' 
                : 'Point removed. ${_currentPolygonPoints.length} points remaining',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _cancelDrawing() {
    setState(() {
      _currentPolygonPoints.clear();
      _isDrawingMode = false;
    });
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Drawing cancelled'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.grey,
      ),
    );
  }

  void _goToUserLocation() {
    if (_controller != null && _userLocation != null) {
      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _userLocation!,
            zoom: 18.0,
          ),
        ),
      );
    } else if (_userLocation == null) {
      _getCurrentLocation();
    }
  }

  Set<Marker> _getAllMarkers() {
    Set<Marker> allMarkers = {};
    
    // Only add user location marker when NOT in drawing mode
    if (!_isDrawingMode) {
      allMarkers.addAll(_getUserLocationMarker());
    }
    
    // Add drawing point markers with simple dot style
    if (_isDrawingMode) {
      for (int i = 0; i < _currentPolygonPoints.length; i++) {
        allMarkers.add(
          Marker(
            markerId: MarkerId('drawing_point_$i'),
            position: _currentPolygonPoints[i],
            // Use simple dot marker
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed
            ),
            infoWindow: InfoWindow(
              title: i == 0 ? '🎯 Start Point' : '📍 Point ${i + 1}',
              snippet: 'Lat: ${_currentPolygonPoints[i].latitude.toStringAsFixed(4)}, Lng: ${_currentPolygonPoints[i].longitude.toStringAsFixed(4)}',
            ),
            consumeTapEvents: false,
            anchor: const Offset(0.5, 1.0), // Anchor at bottom center for pin
          ),
        );
      }
    }
    
    return allMarkers;
  }

  Set<Polygon> _getDrawingPointCircles() {
    if (_currentPolygonPoints.isEmpty || !_isDrawingMode) return {};
    
    Set<Polygon> circles = {};
    
    for (int i = 0; i < _currentPolygonPoints.length; i++) {
      final center = _currentPolygonPoints[i];
      final radius = 0.00015; // Small radius for red dot
      final circlePoints = _createCirclePoints(center, radius);
      
      circles.add(
        Polygon(
          polygonId: PolygonId('point_dot_$i'),
          points: circlePoints,
          strokeColor: Colors.red,
          strokeWidth: 2,
          fillColor: Colors.red.withOpacity(0.8),
        ),
      );
    }
    
    return circles;
  }

  List<LatLng> _createCirclePoints(LatLng center, double radius) {
    List<LatLng> points = [];
    const int numberOfPoints = 20;
    
    for (int i = 0; i < numberOfPoints; i++) {
      double angle = (i * 2 * math.pi) / numberOfPoints;
      double lat = center.latitude + radius * math.cos(angle);
      double lng = center.longitude + radius * math.sin(angle);
      points.add(LatLng(lat, lng));
    }
    
    return points;
  }

  Set<Polyline> _getCurrentPolylineSet() {
    if (_currentPolygonPoints.length < 2) return {};
    
    return {
      Polyline(
        polylineId: const PolylineId('current_drawing_line'),
        points: _currentPolygonPoints,
        color: Colors.orange,
        width: 3,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
  }

  Set<Marker> _getUserLocationMarker() {
    if (_userLocation == null || _locationLoading) return {};
    
    return {
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'You are here',
        ),
      ),
    };
  }

  double _calculateArea(List<LatLng> points) {
    // Simple area calculation (approximate, for display purposes)
    if (points.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    area = area.abs() / 2.0;
    
    // Convert to approximate acres (very rough conversion)
    return area * 247105; // Square degrees to acres approximation
  }

  LatLngBounds _getBoundsFromPoints(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  List<Widget> _buildFieldNameOverlays() {
    final fieldState = Provider.of<FieldState>(context, listen: false);
    if (_controller == null) return [];
    
    List<Widget> overlays = [];
    
    for (var field in fieldState.fields) {
      final points = (field['points'] as List).map((point) => 
        LatLng(point['lat'], point['lng'])
      ).toList();
      
      if (points.isNotEmpty) {
        // Calculate the center point of the field
        final centerLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
        final centerLng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
        final centerPoint = LatLng(centerLat, centerLng);
        
        // Convert lat/lng to screen coordinates
        _controller!.getScreenCoordinate(centerPoint).then((screenCoordinate) {
          if (mounted) {
            setState(() {
              // This will trigger a rebuild with the updated overlay positions
            });
          }
        });
        
        // For now, we'll use a simple positioned widget
        // Note: This is a simplified approach. For production, you'd want to use a more sophisticated
        // coordinate conversion system that updates with map movements
        overlays.add(
          FutureBuilder<ScreenCoordinate>(
            future: _controller!.getScreenCoordinate(centerPoint),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final screenCoord = snapshot.data!;
              
              return Positioned(
                left: screenCoord.x.toDouble() - 40, // Center the text
                top: screenCoord.y.toDouble() - 12, // Center vertically
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    field['name'] ?? 'Unnamed Field',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }
    }
    
    return overlays;
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final profileState = Provider.of<ProfileState>(context);
    final accountDetails = profileState.accountDetails;
    final shippingAddress = profileState.shippingAddress;
    final imageFile = profileState.imageFile;
    _imageFile = imageFile; // Keep local state in sync with global state

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () {
              // Handle account deactivation
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Deactivate Account'),
                    content: const Text('Are you sure you want to deactivate your account?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Handle deactivation
                          Navigator.of(context).pop();
                        },
                        child: const Text('Deactivate'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.shade50,
                              border: Border.all(
                                color: Colors.green.shade200,
                                width: 2,
                              ),
                              image: _imageFile != null
                                  ? DecorationImage(
                                      image: kIsWeb
                                          ? NetworkImage(_imageFile!.path)
                                          : FileImage(File(_imageFile!.path))
                                              as ImageProvider,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _imageFile == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.green,
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Farmer ${accountDetails['First Name']}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Balance: \$5,000',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          profileState.locationDisplay,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'example@mail.com',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '+1 (070) 123-4567',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Account Details', _editAccountDetails),
                      const SizedBox(height: 16),
                      ...accountDetails.entries.map((entry) => _buildDetailRow(entry.key, entry.value)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Shipping Address', _editShippingAddress),
                      const SizedBox(height: 16),
                      ...shippingAddress.entries.map((entry) => _buildDetailRow(entry.key, entry.value)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentMethodSection(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final profileState = Provider.of<ProfileState>(context, listen: false);
        profileState.updateImage(pickedFile);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _editAccountDetails() async {
    final profileState = Provider.of<ProfileState>(context, listen: false);
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        Map<String, String> tempDetails = Map.from(profileState.accountDetails);
        return AlertDialog(
          title: const Text('Edit Account Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: tempDetails.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    decoration: InputDecoration(labelText: key),
                    controller: TextEditingController(text: tempDetails[key]),
                    onChanged: (value) => tempDetails[key] = value,
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(tempDetails),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      profileState.updateAccountDetails(result);
    }
  }

  Future<void> _editShippingAddress() async {
    final profileState = Provider.of<ProfileState>(context, listen: false);
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        Map<String, String> tempAddress = Map.from(profileState.shippingAddress);
        return AlertDialog(
          title: const Text('Edit Shipping Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: tempAddress.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    decoration: InputDecoration(labelText: key),
                    controller: TextEditingController(text: tempAddress[key]),
                    onChanged: (value) => tempAddress[key] = value,
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(tempAddress),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      profileState.updateShippingAddress(result);
    }
  }

  Future<void> _editPaymentMethod() async {
    final profileState = Provider.of<ProfileState>(context, listen: false);
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        Map<String, String> tempPayment = Map.from(profileState.paymentMethod);
        return AlertDialog(
          title: const Text('Edit Payment Method'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Card Number'),
                    controller: TextEditingController(text: tempPayment['Card Number']),
                    onChanged: (value) => tempPayment['Card Number'] = value,
                    keyboardType: TextInputType.number,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Card Holder Name'),
                    controller: TextEditingController(text: tempPayment['Card Holder']),
                    onChanged: (value) => tempPayment['Card Holder'] = value,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                    controller: TextEditingController(text: tempPayment['Expiry']),
                    onChanged: (value) => tempPayment['Expiry'] = value,
                    keyboardType: TextInputType.datetime,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(tempPayment),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      profileState.updatePaymentMethod(result);
    }
  }

  Widget _buildSectionHeader(String title, VoidCallback onEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Payment Methods', _editPaymentMethod),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: Icon(
                      Icons.credit_card,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '**** **** **** 1234',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'FARMER NAME',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Expires 12/25',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileState extends ChangeNotifier {
  XFile? imageFile;
  Map<String, String> accountDetails = {
    'First Name': 'John',
    'Last Name': 'Doe',
    'Date of Birth': '01 Jan, 1990',
    'Gender': 'Male',
  };

  Map<String, String> shippingAddress = {
    'Address': '123 Farm Street',
    'City': 'Farmville',
    'State': 'CA',
    'Country': 'United States',
    'Zip Code': '12345',
  };

  Map<String, String> paymentMethod = {
    'Card Number': '**** **** **** 1234',
    'Card Holder': 'FARMER NAME',
    'Expiry': '12/25',
  };

  void updateImage(XFile? newImage) {
    imageFile = newImage;
    notifyListeners();
  }

  void updateAccountDetails(Map<String, String> newDetails) {
    accountDetails = newDetails;
    notifyListeners();
  }

  void updateShippingAddress(Map<String, String> newAddress) {
    shippingAddress = newAddress;
    notifyListeners();
  }

  void updatePaymentMethod(Map<String, String> newPaymentMethod) {
    paymentMethod = newPaymentMethod;
    notifyListeners();
  }

  String get locationDisplay {
    final city = shippingAddress['City'] ?? '';
    final state = shippingAddress['State'] ?? '';
    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city, $state';
    } else if (state.isNotEmpty) {
      return state;
    }
    return 'Location not set';
  }

  String get welcomeMessage {
    final firstName = accountDetails['First Name'] ?? '';
    return 'Welcome Farmer $firstName!';
  }
} 