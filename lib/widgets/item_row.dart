import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../screens/new_bill_screen.dart';

class ItemRow extends StatefulWidget {
  final BillItemData data;
  final Function(BillItemData) onUpdate;
  final VoidCallback onDelete;

  const ItemRow({
    super.key,
    required this.data,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<ItemRow> {
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  Item? _selectedItem;
  List<Item> _allItems = [];
  List<Item> _filteredItems = [];
  bool _showDropdown = false;
  final _searchController = TextEditingController();
  bool _quantityError = false;
  bool _priceError = false;

  @override
  void initState() {
    super.initState();
    _allItems = DatabaseService.getAllItems();
    _filteredItems = _allItems;
    _quantityController.text = widget.data.quantity.toString();
    _priceController.text =
        widget.data.price > 0 ? widget.data.price.toString() : '';

    if (widget.data.itemId != null) {
      _selectedItem = _allItems.firstWhere(
        (item) => item.id == widget.data.itemId,
        orElse: () => _allItems.first,
      );
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems.where((item) {
          return item.name.contains(query) ||
              item.serialNo.contains(query);
        }).toList();
      }
    });
  }

  void _selectItem(Item item) {
    setState(() {
      _selectedItem = item;
      _showDropdown = false;
      _searchController.clear();
      _filteredItems = _allItems;
    });
    _updateData();
  }

  void _updateData() {
    final quantityText = _quantityController.text.trim();
    final priceText = _priceController.text.trim();

    // Validate quantity
    final quantity = double.tryParse(quantityText);
    final isQuantityValid = quantity != null && quantity > 0;

    // Validate price
    final price = double.tryParse(priceText);
    final isPriceValid = priceText.isEmpty || (price != null && price >= 0);

    setState(() {
      _quantityError = quantityText.isNotEmpty && !isQuantityValid;
      _priceError = priceText.isNotEmpty && !isPriceValid;
    });

    final double validQuantity = isQuantityValid ? quantity : 0.0;
    final double validPrice = (price != null && price >= 0) ? price : 0.0;
    final double amount = validQuantity * validPrice;

    final updatedData = BillItemData(
      id: widget.data.id,
      itemId: _selectedItem?.id,
      itemName: _selectedItem?.name,
      unit: _selectedItem?.unit,
      quantity: validQuantity,
      price: validPrice,
      amount: amount,
    );

    widget.onUpdate(updatedData);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Item dropdown
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showDropdown = !_showDropdown;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedItem?.name ?? 'آئٹم منتخب کریں',
                              style: GoogleFonts.notoNastaliqUrdu(
                                fontSize: 14,
                                color: _selectedItem != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            _showDropdown
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Unit
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _selectedItem?.unit ?? '-',
                      style: GoogleFonts.notoNastaliqUrdu(
                        fontSize: 14,
                        color: _selectedItem != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Quantity
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _quantityError ? Colors.red : Colors.grey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _quantityError ? Colors.red : Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: _quantityError ? Colors.red : Colors.black,
                    ),
                    onChanged: (_) => _updateData(),
                  ),
                ),
                const SizedBox(width: 4),
                // Price
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _priceError ? Colors.red : Colors.grey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _priceError ? Colors.red : Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: _priceError ? Colors.red : Colors.black,
                    ),
                    onChanged: (_) => _updateData(),
                  ),
                ),
                const SizedBox(width: 4),
                // Amount (calculated)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      widget.data.amount.toStringAsFixed(0),
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // Delete button
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
            // Dropdown list
            if (_showDropdown) ...[
              const SizedBox(height: 8),
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'تلاش کریں (نام یا نمبر)',
                  hintStyle: GoogleFonts.notoNastaliqUrdu(),
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                ),
                style: GoogleFonts.notoNastaliqUrdu(),
                onChanged: _filterItems,
              ),
              const SizedBox(height: 4),
              // Items list
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        item.name,
                        style: GoogleFonts.notoNastaliqUrdu(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${item.serialNo} - ${item.unit}',
                        style: GoogleFonts.roboto(fontSize: 12),
                      ),
                      onTap: () => _selectItem(item),
                      selected: _selectedItem?.id == item.id,
                      selectedTileColor: Colors.blue[50],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
