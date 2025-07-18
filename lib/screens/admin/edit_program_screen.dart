import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProgramScreen extends StatefulWidget {
  final String programId;

  const EditProgramScreen({super.key, required this.programId});

  @override
  State<EditProgramScreen> createState() => _EditProgramScreenState();
}

class _EditProgramScreenState extends State<EditProgramScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _imagePathController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgramData();
  }

  Future<void> _loadProgramData() async {
    final doc = await FirebaseFirestore.instance.collection('programs').doc(widget.programId).get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _durationController.text = data['duration']?.toString() ?? '';
      _imagePathController.text = data['imageAssetPath'] ?? '';
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _updateProgram() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('programs').doc(widget.programId).update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'duration': int.tryParse(_durationController.text.trim()) ?? 0,
        'imageAssetPath': _imagePathController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program başarıyla güncellendi')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programı Düzenle')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Program Adı'),
                validator: (value) => value!.isEmpty ? 'Lütfen bir ad girin' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Açıklama gerekli' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Süre (gün)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Süre gerekli' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _imagePathController,
                decoration: const InputDecoration(labelText: 'Görsel (assets yolu)'),
                validator: (value) => value!.isEmpty ? 'Görsel yolu gerekli' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _updateProgram,
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              )
            ],
          ),
        ),
      ),
    );
  }
}
