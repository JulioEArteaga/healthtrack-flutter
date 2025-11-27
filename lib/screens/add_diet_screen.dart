import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/diet.dart';
import '../services/firestore_service.dart';

class AddDietScreen extends StatefulWidget {
  final Diet? editDiet;

  const AddDietScreen({super.key, this.editDiet});

  @override
  State<AddDietScreen> createState() => _AddDietScreenState();
}

class _AddDietScreenState extends State<AddDietScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _calories = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool saving = false;

  @override
  void initState() {
    super.initState();

    final diet = widget.editDiet;
    if (diet != null) {
      _name.text = diet.name;
      _description.text = diet.description;
      _calories.text = diet.calories.toString();
      selectedDate = diet.date;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _calories.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_name.text.trim().isEmpty ||
        _description.text.trim().isEmpty ||
        _calories.text.trim().isEmpty) {
      _showMessage("Llena todos los campos");
      return false;
    }

    final calories = int.tryParse(_calories.text.trim());
    if (calories == null || calories <= 0) {
      _showMessage("Ingresa un número válido de calorías");
      return false;
    }

    return true;
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> saveDiet() async {
    if (!_validate()) return;

    setState(() => saving = true);

    final firestore = FirestoreService();

    final diet = Diet(
      id: widget.editDiet?.id ?? const Uuid().v4(),
      uid: firestore.uid,
      name: _name.text.trim(),
      description: _description.text.trim(),
      calories: int.parse(_calories.text.trim()),
      date: selectedDate,
    );

    try {
      if (widget.editDiet == null) {
        await firestore.addDiet(diet);
      } else {
        await firestore.updateDiet(diet);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      _showMessage("Error al guardar la dieta");
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editDiet != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        elevation: 0,
        title: Text(
          isEditing ? "Editar Dieta" : "Agregar Dieta",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _TopWaveClipper(),
              child: Container(
                height: 180,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _BottomWaveClipper(),
              child: Container(
                height: 160,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  _inputField(
                    controller: _name,
                    hint: "Nombre",
                    icon: Icons.restaurant,
                  ),

                  const SizedBox(height: 18),

                  _inputField(
                    controller: _description,
                    hint: "Descripción",
                    icon: Icons.description,
                  ),

                  const SizedBox(height: 18),

                  _inputField(
                    controller: _calories,
                    hint: "Calorías",
                    icon: Icons.local_fire_department,
                    number: true,
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDate: selectedDate,
                      );

                      if (picked != null && mounted) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      "Seleccionar fecha: ${selectedDate.toString().split(' ')[0]}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: saving ? null : saveDiet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isEditing ? "Actualizar" : "Guardar",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                            ),
                          ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool number = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFB71C1C)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

/// 🌊 OLA SUPERIOR
class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

/// 🌊 OLA INFERIOR
class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 40);
    path.quadraticBezierTo(size.width / 2, 0, size.width, 50);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}
