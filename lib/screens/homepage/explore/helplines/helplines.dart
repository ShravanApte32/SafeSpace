// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HelplinePage extends StatefulWidget {
  const HelplinePage({super.key});

  @override
  State<HelplinePage> createState() => _HelplinePageState();
}

class _HelplinePageState extends State<HelplinePage>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _customNumbers = [
    {
      'name': 'Local Emergency',
      'phone': '112',
      'type': 'Emergency',
      'description': 'Local emergency services',
      'icon': Icons.emergency,
      'color': Colors.red,
    },
    {
      'name': 'Trusted Friend',
      'phone': '',
      'type': 'Personal',
      'description': 'Your trusted contact',
      'icon': Icons.person,
      'color': Colors.purple,
    },
    {
      'name': 'Counselor',
      'phone': '',
      'type': 'Mental Health',
      'description': 'Professional counseling',
      'icon': Icons.psychology,
      'color': Colors.blue,
    },
  ];

  String _selectedRegion = 'Global';
  final List<String> _regions = [
    'Global',
    'North America',
    'Europe',
    'Asia',
    'Africa',
    'South America',
    'Oceania',
  ];

  final Map<String, List<Map<String, dynamic>>> _regionalHelplines = {
    'Global': [
      {
        'name': 'International Emergency',
        'phone': '112',
        'type': 'Emergency',
        'description': 'Standard emergency number',
        'icon': Icons.public,
        'color': Colors.red,
      },
      {
        'name': 'Suicide Prevention',
        'phone': '+1-800-273-8255',
        'type': 'Mental Health',
        'description': 'International suicide prevention lifeline',
        'icon': Icons.health_and_safety,
        'color': Colors.blue,
      },
    ],
    'North America': [
      {
        'name': 'Emergency Services',
        'phone': '911',
        'type': 'Emergency',
        'description': 'Police, Fire, Ambulance',
        'icon': Icons.emergency,
        'color': Colors.red,
      },
      {
        'name': 'Suicide Prevention',
        'phone': '+1-800-273-8255',
        'type': 'Mental Health',
        'description': 'National Suicide Prevention Lifeline',
        'icon': Icons.health_and_safety,
        'color': Colors.blue,
      },
      {
        'name': 'Crisis Text Line',
        'phone': '741741',
        'type': 'Mental Health',
        'description': 'Text for crisis support',
        'icon': Icons.sms,
        'color': Colors.green,
      },
      {
        'name': 'Domestic Violence',
        'phone': '+1-800-799-7233',
        'type': 'Domestic Abuse',
        'description': 'National Domestic Violence Hotline',
        'icon': Icons.security,
        'color': Colors.purple,
      },
    ],
    'Europe': [
      {
        'name': 'European Emergency',
        'phone': '112',
        'type': 'Emergency',
        'description': 'EU-wide emergency number',
        'icon': Icons.emergency,
        'color': Colors.red,
      },
      {
        'name': 'Samaritans UK',
        'phone': '116 123',
        'type': 'Mental Health',
        'description': '24/7 emotional support',
        'icon': Icons.phone_in_talk,
        'color': Colors.blue,
      },
    ],
    'Asia': [
      {
        'name': 'Emergency India',
        'phone': '112',
        'type': 'Emergency',
        'description': 'National emergency number',
        'icon': Icons.emergency,
        'color': Colors.red,
      },
      {
        'name': 'Befrienders KL',
        'phone': '+603-76272929',
        'type': 'Mental Health',
        'description': 'Malaysia emotional support',
        'icon': Icons.health_and_safety,
        'color': Colors.blue,
      },
    ],
    'Africa': [
      {
        'name': 'South Africa Emergency',
        'phone': '10111',
        'type': 'Emergency',
        'description': 'Police emergency',
        'icon': Icons.emergency,
        'color': Colors.red,
      },
    ],
    'South America': [
      {
        'name': 'Emergency Brazil',
        'phone': '190',
        'type': 'Emergency',
        'description': 'Police emergency',
        'icon': Icons.emergency,
        'color': Colors.red,
      },
    ],
    'Oceania': [
      {
        'name': 'Emergency Australia',
        'phone': '000',
        'type': 'Emergency',
        'description': 'Police, Fire, Ambulance',
        'icon': Icons.emergency,
        'color': Colors.red,
      },
      {
        'name': 'Lifeline Australia',
        'phone': '13 11 14',
        'type': 'Mental Health',
        'description': '24/7 crisis support',
        'icon': Icons.health_and_safety,
        'color': Colors.blue,
      },
    ],
  };

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredHelplines = [];
  late AnimationController _fabAnimationController;
  bool _isSearching = false;
  int _selectedCategory = 0;
  final List<String> _categories = [
    'All',
    'Emergency',
    'Mental Health',
    'Personal',
    'Domestic Abuse',
  ];

  // Light Pink Theme Colors
  final Color _primaryPink = const Color(0xFFFFF0F5);
  final Color _accentPink = const Color(0xFFFFB6C1);
  final Color _darkPink = const Color(0xFFFF69B4);
  final Color _textColor = const Color(0xFF8B4E6D);
  // final Color _cardColor = Colors.white;
  final Color _shadowColor = const Color(0x33FFB6C1);

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _updateFilteredHelplines();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _updateFilteredHelplines() {
    final regional = _regionalHelplines[_selectedRegion] ?? [];
    final allHelplines = [...regional, ..._customNumbers];

    List<Map<String, dynamic>> filtered = allHelplines;

    // Apply category filter
    if (_selectedCategory > 0) {
      final category = _categories[_selectedCategory];
      filtered = filtered
          .where((helpline) => helpline['type'] == category)
          .toList();
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((helpline) {
        final name = helpline['name']?.toString().toLowerCase() ?? '';
        final type = helpline['type']?.toString().toLowerCase() ?? '';
        final description =
            helpline['description']?.toString().toLowerCase() ?? '';

        return name.contains(query) ||
            type.contains(query) ||
            description.contains(query);
      }).toList();
    }

    setState(() {
      _filteredHelplines = filtered;
    });
  }

  void _launchPhone(String phone) async {
    if (phone.isEmpty) {
      _showSnackBar('Phone number is empty', isError: true);
      return;
    }

    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showSnackBar('Could not launch $phone', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade300 : _darkPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showAddCustomDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddContactSheet(
        onSave: (contact) {
          setState(() {
            _customNumbers.add(contact);
          });
          _updateFilteredHelplines();
          _showSnackBar('Contact added successfully!');
        },
        pinkTheme: _getThemeColors(),
      ),
    );
  }

  Map<String, Color> _getThemeColors() {
    return {
      'primary': _primaryPink,
      'accent': _accentPink,
      'dark': _darkPink,
      'text': _textColor,
      'shadow': _shadowColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryPink,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            backgroundColor: _primaryPink,
            foregroundColor: _textColor,
            elevation: 0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: AnimatedOpacity(
                opacity: _isSearching ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  'Support Helplines',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryPink, _accentPink.withOpacity(0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 80, left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.favorite, color: _darkPink, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Help is here',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      Text(
                        'You are not alone',
                        style: TextStyle(
                          fontSize: 16,
                          color: _textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _updateFilteredHelplines();
                    }
                  });
                },
              ),
            ],
          ),

          // Search Bar
          if (_isSearching)
            SliverToBoxAdapter(
              child: _AnimatedSearchBar(
                controller: _searchController,
                onChanged: (value) => _updateFilteredHelplines(),
                pinkTheme: _getThemeColors(),
              ),
            ),

          // Region Selector & Categories
          SliverToBoxAdapter(
            child: _TopSection(
              selectedRegion: _selectedRegion,
              regions: _regions,
              selectedCategory: _selectedCategory,
              categories: _categories,
              onRegionChanged: (value) {
                setState(() {
                  _selectedRegion = value!;
                  _updateFilteredHelplines();
                });
              },
              onCategoryChanged: (index) {
                setState(() {
                  _selectedCategory = index;
                  _updateFilteredHelplines();
                });
              },
              pinkTheme: _getThemeColors(),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: _QuickActionsSection(
              onEmergency: () => _launchPhone('112'),
              onAddContact: _showAddCustomDialog,
              onShare: _shareAllNumbers,
              pinkTheme: _getThemeColors(),
            ),
          ),

          // Helplines List
          if (_filteredHelplines.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: AnimationLimiter(
                child: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final helpline = _filteredHelplines[index];
                    final regionalLength =
                        _regionalHelplines[_selectedRegion]?.length ?? 0;
                    final isCustom = index >= regionalLength;

                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _HelplineCard(
                            helpline: helpline,
                            isCustom: isCustom,
                            onCall: () => _launchPhone(
                              helpline['phone']?.toString() ?? '',
                            ),
                            onEdit: isCustom
                                ? () => _editCustomHelpline(
                                    index - regionalLength,
                                  )
                                : null,
                            onDelete: isCustom
                                ? () => _deleteCustomHelpline(
                                    index - regionalLength,
                                  )
                                : null,
                            pinkTheme: _getThemeColors(),
                          ),
                        ),
                      ),
                    );
                  }, childCount: _filteredHelplines.length),
                ),
              ),
            )
          else
            SliverFillRemaining(
              child: _EmptyState(
                pinkTheme: _getThemeColors(),
                onAddContact: _showAddCustomDialog,
              ),
            ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton(
          onPressed: _showAddCustomDialog,
          backgroundColor: _darkPink,
          foregroundColor: Colors.white,
          elevation: 8,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  void _editCustomHelpline(int index) async {
    if (index < 0 || index >= _customNumbers.length) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddContactSheet(
        contact: _customNumbers[index],
        onSave: (updatedContact) {
          setState(() {
            _customNumbers[index] = updatedContact;
          });
          _updateFilteredHelplines();
          _showSnackBar('Contact updated successfully!');
        },
        pinkTheme: _getThemeColors(),
      ),
    );
  }

  void _deleteCustomHelpline(int index) {
    if (index < 0 || index >= _customNumbers.length) return;

    showDialog(
      context: context,
      builder: (_) => _DeleteDialog(
        contactName:
            _customNumbers[index]['name']?.toString() ?? 'Unknown Contact',
        onDelete: () {
          setState(() {
            _customNumbers.removeAt(index);
          });
          _updateFilteredHelplines();
          _showSnackBar('Contact deleted');
          Navigator.pop(context);
        },
        pinkTheme: _getThemeColors(),
      ),
    );
  }

  void _shareAllNumbers() {
    _showSnackBar('Sharing ${_filteredHelplines.length} contacts');
    // Implement share functionality
  }
}

// Enhanced Components with Beautiful Design
class _AnimatedSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Map<String, Color> pinkTheme;

  const _AnimatedSearchBar({
    required this.controller,
    required this.onChanged,
    required this.pinkTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Hero(
        tag: 'search',
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(25),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search helplines...',
              prefixIcon: Icon(Icons.search, color: pinkTheme['dark']),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopSection extends StatelessWidget {
  final String selectedRegion;
  final List<String> regions;
  final int selectedCategory;
  final List<String> categories;
  final ValueChanged<String?> onRegionChanged;
  final ValueChanged<int> onCategoryChanged;
  final Map<String, Color> pinkTheme;

  const _TopSection({
    required this.selectedRegion,
    required this.regions,
    required this.selectedCategory,
    required this.categories,
    required this.onRegionChanged,
    required this.onCategoryChanged,
    required this.pinkTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Region Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: pinkTheme['shadow'] ?? const Color(0x33FFB6C1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.public, color: pinkTheme['dark'], size: 20),
                const SizedBox(width: 12),
                Text(
                  'Region:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: pinkTheme['text'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRegion,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: pinkTheme['dark'],
                      ),
                      items: regions.map((region) {
                        return DropdownMenuItem(
                          value: region,
                          child: Text(
                            region,
                            style: TextStyle(color: pinkTheme['text']),
                          ),
                        );
                      }).toList(),
                      onChanged: onRegionChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Categories
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(categories[index]),
                    selected: selectedCategory == index,
                    onSelected: (selected) => onCategoryChanged(index),
                    selectedColor: pinkTheme['accent'],
                    labelStyle: TextStyle(
                      color: selectedCategory == index
                          ? Colors.white
                          : pinkTheme['text'],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onEmergency;
  final VoidCallback onAddContact;
  final VoidCallback onShare;
  final Map<String, Color> pinkTheme;

  const _QuickActionsSection({
    required this.onEmergency,
    required this.onAddContact,
    required this.onShare,
    required this.pinkTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            icon: Icons.emergency,
            label: 'Emergency',
            color: Colors.red,
            onTap: onEmergency,
          ),
          _ActionButton(
            icon: Icons.add_circle,
            label: 'Add Contact',
            color: pinkTheme['dark']!,
            onTap: onAddContact,
          ),
          _ActionButton(
            icon: Icons.share,
            label: 'Share',
            color: Colors.purple,
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _HelplineCard extends StatelessWidget {
  final Map<String, dynamic> helpline;
  final bool isCustom;
  final VoidCallback onCall;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Map<String, Color> pinkTheme;

  const _HelplineCard({
    required this.helpline,
    required this.isCustom,
    required this.onCall,
    this.onEdit,
    this.onDelete,
    required this.pinkTheme,
  });

  @override
  Widget build(BuildContext context) {
    // Safe access to properties with null checks
    final String name = helpline['name']?.toString() ?? 'Unknown';
    final String phone = helpline['phone']?.toString() ?? '';
    final String type = helpline['type']?.toString() ?? 'Personal';
    final String description = helpline['description']?.toString() ?? '';
    final IconData icon = _getIcon(helpline['icon']);
    final Color color = _getColor(helpline['color']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: pinkTheme['shadow'] ?? const Color(0x33FFB6C1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getTypeColor(type),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCustom && (onEdit != null || onDelete != null))
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: pinkTheme['text']),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  color: pinkTheme['dark'],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Edit',
                                  style: TextStyle(color: pinkTheme['text']),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') onEdit?.call();
                          if (value == 'delete') onDelete?.call();
                        },
                      ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        phone.isEmpty ? 'No number set' : phone,
                        style: TextStyle(
                          fontSize: 16,
                          color: phone.isEmpty
                              ? Colors.grey
                              : pinkTheme['dark'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (phone.isNotEmpty)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              pinkTheme['accent'] ?? const Color(0xFFFFB6C1),
                              pinkTheme['dark'] ?? const Color(0xFFFF69B4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (pinkTheme['dark'] ?? const Color(0xFFFF69B4))
                                      .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: onCall,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isCustom)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  'CUSTOM',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIcon(dynamic iconData) {
    if (iconData is IconData) {
      return iconData;
    } else if (iconData is String) {
      // Map string to IconData
      switch (iconData) {
        case 'emergency':
          return Icons.emergency;
        case 'person':
          return Icons.person;
        case 'health_and_safety':
          return Icons.health_and_safety;
        case 'psychology':
          return Icons.psychology;
        case 'security':
          return Icons.security;
        case 'phone_in_talk':
          return Icons.phone_in_talk;
        case 'sms':
          return Icons.sms;
        case 'public':
          return Icons.public;
        default:
          return Icons.contact_phone;
      }
    }
    return Icons.contact_phone;
  }

  Color _getColor(dynamic colorData) {
    if (colorData is Color) {
      return colorData;
    }
    return Colors.blue; // Default color
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
        return Colors.red;
      case 'mental health':
        return Colors.blue;
      case 'domestic abuse':
        return Colors.purple;
      case 'personal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// ... (Keep the _AddContactSheet, _DeleteDialog, and _EmptyState classes the same as in the previous version)
// Note: You'll need to add null safety checks to those classes as well

class _AddContactSheet extends StatefulWidget {
  final Map<String, dynamic>? contact;
  final Function(Map<String, dynamic>) onSave;
  final Map<String, Color> pinkTheme;

  const _AddContactSheet({
    this.contact,
    required this.onSave,
    required this.pinkTheme,
  });

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _typeController;
  late TextEditingController _descController;
  String _selectedIcon = 'person';
  Color _selectedColor = Colors.blue;

  final Map<String, IconData> _icons = {
    'person': Icons.person,
    'emergency': Icons.emergency,
    'health': Icons.health_and_safety,
    'psychology': Icons.psychology,
    'security': Icons.security,
    'phone': Icons.phone_in_talk,
    'sms': Icons.sms,
    'public': Icons.public,
  };

  final List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.contact?['name']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.contact?['phone']?.toString() ?? '',
    );
    _typeController = TextEditingController(
      text: widget.contact?['type']?.toString() ?? 'Personal',
    );
    _descController = TextEditingController(
      text: widget.contact?['description']?.toString() ?? '',
    );
    _selectedIcon = widget.contact?['icon']?.toString() ?? 'person';
    _selectedColor = _getColor(widget.contact?['color']) ?? Colors.blue;
  }

  Color? _getColor(dynamic colorData) {
    if (colorData is Color) return colorData;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contact == null ? 'Add Contact' : 'Edit Contact',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.pinkTheme['text'],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Contact Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _typeController,
                          decoration: InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Choose Icon:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.pinkTheme['text'],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _icons.length,
                            itemBuilder: (context, index) {
                              final iconKey = _icons.keys.elementAt(index);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedIcon = iconKey),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: _selectedIcon == iconKey
                                          ? widget.pinkTheme['accent']
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedIcon == iconKey
                                            ? widget.pinkTheme['dark']!
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Icon(
                                      _icons[iconKey],
                                      color: _selectedIcon == iconKey
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Choose Color:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.pinkTheme['text'],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _colors.length,
                            itemBuilder: (context, index) {
                              final color = _colors[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedColor = color),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(20),
                                      border: _selectedColor == color
                                          ? Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            )
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          side: BorderSide(color: widget.pinkTheme['dark']!),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: widget.pinkTheme['dark']),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_nameController.text.isNotEmpty &&
                              _phoneController.text.isNotEmpty) {
                            widget.onSave({
                              'name': _nameController.text,
                              'phone': _phoneController.text,
                              'type': _typeController.text,
                              'description': _descController.text,
                              'icon': _selectedIcon,
                              'color': _selectedColor,
                            });
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.pinkTheme['dark'],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  final String contactName;
  final VoidCallback onDelete;
  final Map<String, Color> pinkTheme;

  const _DeleteDialog({
    required this.contactName,
    required this.onDelete,
    required this.pinkTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              'Delete Contact?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: pinkTheme['text'],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete $contactName?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Map<String, Color> pinkTheme;
  final VoidCallback onAddContact;

  const _EmptyState({required this.pinkTheme, required this.onAddContact});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.contact_phone, size: 80, color: pinkTheme['accent']),
        const SizedBox(height: 20),
        Text(
          'No contacts found',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: pinkTheme['text'],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Try a different search or add a new contact',
          style: TextStyle(color: pinkTheme['text']!.withOpacity(0.7)),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onAddContact,
          style: ElevatedButton.styleFrom(
            backgroundColor: pinkTheme['dark'],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add First Contact'),
        ),
      ],
    );
  }
}
