import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'emotion_detection.dart';
import 'translate_sign_to_text.dart';
import '../../text_to_sign.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showResults = false;

  // Main features data
  final List<Map<String, dynamic>> _mainFeatures = [
    {
      'title': 'Text to Sign',
      'description': 'Convert text into sign animations',
      'icon': Icons.text_fields,
      'screen': TextToSignScreen(),
      'color': Color(0xFFB2D7F0),
    },
    {
      'title': 'Sign to Text',
      'description': 'Translate signs to text or speech',
      'icon': Icons.g_translate,
      'screen': TranslateSignToTextScreen(),
      'color': Color(0xFFB2D7F0),
    },
    {
      'title': 'Emotion Detection',
      'description': 'Identify sign emotions',
      'icon': Icons.face,
      'screen': EmotionDetectionScreen(),
      'color': Color(0xFFB2D7F0),
    },
  ];

  List<Map<String, dynamic>> get _filteredFeatures {
    if (_searchQuery.isEmpty) return [];
    return _mainFeatures
        .where((feature) =>
            feature['title']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            feature['description']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Search Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB2D7F0), Color(0xFF90CAF9)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Features',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0077B6),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Search through our sign language tools',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Enhanced Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _showResults = value.isNotEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search features...',
                        hintStyle: GoogleFonts.montserrat(
                          color: Colors.grey,
                        ),
                        prefixIcon:
                            Icon(Icons.search, color: Color(0xFF0077B6)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon:
                                    Icon(Icons.clear, color: Color(0xFF0077B6)),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _showResults = false;
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Results or Features
            Expanded(
              child:
                  _showResults ? _buildSearchResults() : _buildFeaturesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return _filteredFeatures.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No results found',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: _filteredFeatures.length,
            itemBuilder: (context, index) {
              final feature = _filteredFeatures[index];
              return _buildFeatureCard(feature);
            },
          );
  }

  Widget _buildFeaturesList() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text(
          'Available Features',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 20),
        ..._mainFeatures.map((feature) => _buildFeatureCard(feature)).toList(),
      ],
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: feature['color'],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => feature['screen']),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF0077B6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    feature['icon'],
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'],
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        feature['description'],
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF0077B6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
