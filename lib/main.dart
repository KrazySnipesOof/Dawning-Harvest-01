import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

void main() {
  runApp(const MyApp());
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.2, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.green.shade50,
        color: Colors.green,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        items: const [
          Icon(Icons.home, color: Colors.white),
          Icon(Icons.map, color: Colors.white),
          Icon(Icons.person, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dawning Harvest'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.agriculture),
              title: const Text('Start Growing'),
              subtitle: const Text('Begin your farming journey'),
              onTap: () {
                // TODO: Implement growing functionality
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_basket),
              title: const Text('Marketplace'),
              subtitle: const Text('Buy and sell produce'),
              onTap: () {
                // TODO: Implement marketplace functionality
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tips_and_updates),
              title: const Text('Growing Tips'),
              subtitle: const Text('Learn farming techniques'),
              onTap: () {
                // TODO: Implement tips functionality
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Container(
          width: 300,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.green.shade200,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 50,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                'Map Coming Soon!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Will show local farming locations',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  
  // Update state variables
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

  String get locationDisplay {
    final state = shippingAddress['State'] ?? '';
    final country = shippingAddress['Country'] ?? '';
    if (state.isNotEmpty && country.isNotEmpty) {
      return '$state, $country';
    } else if (country.isNotEmpty) {
      return country;
    }
    return 'Location not set';
  }

  String get welcomeMessage {
    final firstName = accountDetails['First Name'] ?? '';
    return 'Welcome Farmer $firstName!';
  }

  Future<void> _editAccountDetails() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        Map<String, String> tempDetails = Map.from(accountDetails);
        return AlertDialog(
          title: const Text('Edit Account Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: accountDetails.keys.map((key) {
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
      setState(() {
        accountDetails = result;
      });
    }
  }

  Future<void> _editShippingAddress() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        Map<String, String> tempAddress = Map.from(shippingAddress);
        return AlertDialog(
          title: const Text('Edit Shipping Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: shippingAddress.keys.map((key) {
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
      setState(() {
        shippingAddress = result;
      });
    }
  }

  Future<void> _editPaymentMethod() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        Map<String, String> tempPayment = Map.from(paymentMethod);
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
      setState(() {
        paymentMethod = result;
      });
    }
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
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
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
            // Only show add button for payment methods
            if (title == 'Payment Methods')
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Add Payment Method'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Card Number',
                                  hintText: '**** **** **** ****',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Card Holder Name',
                                ),
                                textCapitalization: TextCapitalization.characters,
                              ),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Expiry Date',
                                  hintText: 'MM/YY',
                                ),
                                keyboardType: TextInputType.datetime,
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: const Text('Add'),
                            onPressed: () {
                              // Add new payment method logic here
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Payment Methods', () => _editPaymentMethod()),
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
                          paymentMethod['Card Number'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          paymentMethod['Card Holder'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Expires ${paymentMethod['Expiry']}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.power_settings_new, color: Colors.red),
            label: const Text(
              'Deactivate Account',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Deactivate Account'),
                    content: const Text('Are you sure you want to deactivate your account? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: const Text('Deactivate', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          // Handle account deactivation
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8), // Add some padding on the right
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
                      welcomeMessage,
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
                          locationDisplay,
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
} 