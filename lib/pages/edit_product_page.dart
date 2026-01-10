import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import '../models/product.dart';
import 'scan_qr_page.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late TextEditingController _qrController;
  late TextEditingController _specsController;
  String? _selectedCategory;
  
  final List<String> _categories = [
    'Camera IP Pro',
    'Camera IP Home',
    'Smarthome',
    'Thiết bị mạng',
    'Khác',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _imageUrlController = TextEditingController(text: widget.product.imageUrl);
    _qrController = TextEditingController(text: widget.product.qrCode);
    _specsController = TextEditingController(text: widget.product.technicalSpecs);
    
    if (_categories.contains(widget.product.category)) {
      _selectedCategory = widget.product.category;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _qrController.dispose();
    _specsController.dispose();
    super.dispose();
  }

  void _scanQr() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanQrPage()),
    );
    if (result != null && result is String) {
      if (mounted) setState(() => _qrController.text = result);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
      final qr = _qrController.text.trim().isEmpty ? null : _qrController.text.trim();
      // Ensure empty string becomes null explicitly
      final imageUrl = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();
      final specs = _specsController.text.trim().isEmpty ? null : _specsController.text.trim();

      await Supabase.instance.client
          .from('products')
          .update({
            'name': name,
            'price': price,
            'image_url': imageUrl, // This will be null if empty
            'qr_code': qr,
            'category': _selectedCategory,
            'technical_specs': specs,
          })
          .eq('id', widget.product.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật sản phẩm thành công!')),
        );
        Navigator.pop(context, true); // Return true to indicate update
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa Sản Phẩm'),
        actions: [
          IconButton(
             onPressed: () async {
               final confirm = await showDialog(
                 context: context, 
                 builder: (c) => AlertDialog(
                   title: const Text('Xóa Sản Phẩm?'),
                   content: const Text('Hành động này không thể hoàn tác.'),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                     TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                   ],
                 )
               );
               
               if (confirm == true) {
                 try {
                   await Supabase.instance.client.from('products').delete().eq('id', widget.product.id);
                   if (mounted) {
                     Navigator.of(context).popUntil((route) => route.settings.name == '/home');
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa sản phẩm')));
                   }
                 } catch (e) {
                   if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
                 }
               }
             }, 
             icon: const Icon(Icons.delete_forever),
          )
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
                decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                validator: (v) => v == null || v.isEmpty ? 'Nhập tên sản phẩm' : null,
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
                decoration: const InputDecoration(
                  labelText: 'Giá sản phẩm (VNĐ)',
                  suffixText: 'đ',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Nhập giá' : null,
              ),
              const Gap(16),
              TextFormField(
                controller: _specsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Tính năng kỹ thuật',
                  hintText: 'Nhập thông số kỹ thuật...',
                  alignLabelWithHint: true,
                ),
              ),
              const Gap(16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Link Ảnh (URL)',
                  hintText: 'https://...',
                ),
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qrController,
                      decoration: const InputDecoration(labelText: 'Mã QR'),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _scanQr,
                    icon: const Icon(Icons.qr_code_scanner),
                  ),
                ],
              ),
              const Gap(24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Cập Nhật Sản Phẩm', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
