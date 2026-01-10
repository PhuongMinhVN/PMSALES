import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import 'scan_qr_page.dart';

class AddProductPage extends StatefulWidget {
  final Product? productToEdit;
  final Product? productToClone;
  final bool isService;
  const AddProductPage({super.key, this.productToEdit, this.productToClone, this.isService = false});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _qrController = TextEditingController();
  final _specsController = TextEditingController();
  
  String? _selectedCategory;
  final List<String> _categories = [
    'Camera IP Pro',
    'Camera IP Home',
    'Smarthome',
    'Thiết bị mạng',
    'Khác',
    'Dịch vụ',
  ];

  bool _isTwoYearWarranty = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit ?? widget.productToClone;
    if (p != null) {
      _nameController.text = widget.productToClone != null ? '${p.name} (Copy)' : p.name;
      // Format price initially
      _priceController.text = NumberFormat.decimalPattern('vi').format(p.price);
      
      _selectedCategory = _categories.contains(p.category) ? p.category : null;
      _imageUrlController.text = p.imageUrl ?? '';
      _qrController.text = widget.productToClone != null ? '' : (p.qrCode ?? '');
      _specsController.text = p.technicalSpecs ?? '';
      _isTwoYearWarranty = p.warrantyPeriodMonths >= 24;
    } else {
      if (widget.isService) {
        _selectedCategory = 'Dịch vụ';
      }
    }
  }

  void _scanQr() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanQrPage()),
    );
    if (result != null && result is String) {
      setState(() {
        _qrController.text = result;
      });
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn có chắc muốn xoá sản phẩm "${widget.productToEdit!.name}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('products')
          .delete()
          .eq('id', widget.productToEdit!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xoá sản phẩm')));
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      String msg = 'Lỗi xoá: $e';
      if (e.toString().contains('23503')) {
        msg = 'Sản phẩm đã có đơn hàng! Chạy "fix_delete_constraint.sql" để sửa lỗi này.';
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      // Remove all non-digits (commas, dots) before parsing
      final basePrice = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
      final qr = _qrController.text.trim().isEmpty ? null : _qrController.text.trim();
      final imageUrl = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();
      final specs = _specsController.text.trim().isEmpty ? null : _specsController.text.trim();

      int warrantyMonths = 12;
      double finalPrice = basePrice;

      if (_isTwoYearWarranty) {
        warrantyMonths = 24;
        finalPrice = basePrice * 1.20;
      }

      final data = {
        'name': name,
        'price': finalPrice,
        'image_url': imageUrl,
        'qr_code': qr,
        'warranty_period_months': warrantyMonths,
        'category': _selectedCategory,
        'technical_specs': specs,
      };

      if (widget.productToEdit != null) {
         await Supabase.instance.client.from('products').update(data).eq('id', widget.productToEdit!.id);
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
           if (Navigator.canPop(context)) {
             Navigator.pop(context, true);
           } else {
             Navigator.pushReplacementNamed(context, '/home');
           }
         }
      } else {
         data['created_at'] = DateTime.now().toIso8601String();
         await Supabase.instance.client.from('products').insert(data);
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm sản phẩm thành công!')));
            if (Navigator.canPop(context)) {
              Navigator.pop(context, true);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
         }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing 
            ? 'Sửa ${widget.isService ? "Dịch Vụ" : "Sản Phẩm"}' 
            : 'Thêm ${widget.isService ? "Dịch Vụ" : "Sản Phẩm"}'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _isLoading ? null : _deleteProduct,
              tooltip: 'Xoá Sản Phẩm',
            ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            tooltip: 'Về Trang Chủ',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Tên ${widget.isService ? "dịch vụ" : "sản phẩm"}'),
                validator: (v) => v == null || v.isEmpty ? 'Nhập tên ${widget.isService ? "dịch vụ" : "sản phẩm"}' : null,
              ),
              const Gap(16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const Gap(16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Giá ${widget.isService ? "dịch vụ" : "sản phẩm"} (VNĐ)',
                  suffixText: 'đ',
                  helperText: isEditing ? 'Giá hiện tại' : null,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Nhập giá' : null,
              ),
              const Gap(16),
              TextFormField(
                controller: _specsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: widget.isService ? 'Mô tả dịch vụ' : 'Tính năng kỹ thuật',
                  hintText: 'Nhập thông tin chi tiết...',
                  alignLabelWithHint: true,
                ),
              ),
              const Gap(16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Link Ảnh (URL)',
                  hintText: 'https://example.com/image.jpg',
                ),
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qrController,
                      decoration: const InputDecoration(labelText: 'Mã QR (Tùy chọn)'),
                    ),
                  ),
                  const Gap(8),
                  IconButton.filled(
                    onPressed: _scanQr,
                    icon: const Icon(Icons.qr_code_scanner),
                  ),
                ],
              ),
              const Gap(16),
              if (!widget.isService)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bảo hành 2 năm (+20% giá)'),
                value: _isTwoYearWarranty,
                onChanged: (val) {
                  setState(() => _isTwoYearWarranty = val);
                },
              ),
              if (_isTwoYearWarranty && !widget.isService)
                Padding(
                   padding: const EdgeInsets.only(bottom: 16),
                   child: Text(
                     'Giá sau khi cộng thêm: ${(_priceController.text.isNotEmpty ? (double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) * 1.20 : 0).toStringAsFixed(0)} đ',
                     style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                   ),
                ),
              const Gap(24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEditing ? 'Cập Nhật' : 'Lưu ${widget.isService ? "Dịch Vụ" : "Sản Phẩm"}', style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    
    // Clean all non-digits
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) return newValue.copyWith(text: '');
    
    // Parse and format
    // Use Vietnamese locale to get '.' as separator
    double value = double.parse(newText);
    String formatted = NumberFormat.decimalPattern('vi').format(value);
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
