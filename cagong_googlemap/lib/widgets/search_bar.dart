import 'package:flutter/material.dart';
import '../models/cafe.dart';

class SearchBar extends StatelessWidget {
  final List<Cafe> cafes;
  final Function(Cafe) onCafeSelected;

  const SearchBar({
    required this.cafes,
    required this.onCafeSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () => _showSearchInterface(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                '카페 이름 또는 주소 검색...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchInterface(BuildContext context) {
    showSearch(
      context: context,
      delegate: _CafeSearchDelegate(cafes, onCafeSelected),
    );
  }
}

class _CafeSearchDelegate extends SearchDelegate<Cafe?> {
  final List<Cafe> cafes;
  final Function(Cafe) onCafeSelected;

  _CafeSearchDelegate(this.cafes, this.onCafeSelected);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = cafes
        .where((cafe) =>
            cafe.name.toLowerCase().contains(query.toLowerCase()) ||
            cafe.address.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final cafe = results[index];
        return ListTile(
          title: Text(cafe.name),
          subtitle: Text(cafe.address),
          onTap: () {
            onCafeSelected(cafe);
            close(context, cafe);
          },
        );
      },
    );
  }
}
