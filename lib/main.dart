import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(primarySwatch: Colors.blue),
    home: VehicleApp(),
  ));
}


class Vehicle {
  final int id;
  final String model;
  final int year;
  final double mileage;

  Vehicle({required this.id, required this.model, required this.year, required this.mileage});

  Map<String, dynamic> toMap() {
    return {'id': id, 'model': model, 'year': year, 'mileage': mileage};
  }
}

class DatabaseHelper {
  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'vehicles.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE vehicles(id INTEGER PRIMARY KEY, model TEXT, year INTEGER, mileage REAL)');
      },
    );
  }

  static Future<void> insertVehicle(Vehicle vehicle) async {
    final db = await initDB();
    await db.insert('vehicles', vehicle.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteVehicle(int id) async {
    final db = await initDB();
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Vehicle>> getVehicles() async {
    final db = await initDB();
    final List<Map<String, dynamic>> maps = await db.query('vehicles');
    return List.generate(maps.length, (i) {
      return Vehicle(
        id: maps[i]['id'],
        model: maps[i]['model'],
        year: maps[i]['year'],
        mileage: maps[i]['mileage'],
      );
    });
  }
}

class VehicleApp extends StatefulWidget {
  @override
  _VehicleAppState createState() => _VehicleAppState();
}

class _VehicleAppState extends State<VehicleApp> {
  List<Vehicle> vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  void _loadVehicles() async {
    List<Vehicle> loadedVehicles = await DatabaseHelper.getVehicles();
    setState(() {
      vehicles = loadedVehicles;
    });
  }

  Color _getVehicleColor(Vehicle vehicle) {
    int currentYear = DateTime.now().year;
    int age = currentYear - vehicle.year;
    if (vehicle.mileage >= 15) {
      return age <= 5 ? Colors.green : Colors.amber;
    }
    return Colors.red;
  }

  void _showAddVehicleDialog(BuildContext context) {
    final TextEditingController _modelController = TextEditingController();
    final TextEditingController _yearController = TextEditingController();
    final TextEditingController _mileageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Vehicle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _modelController, decoration: InputDecoration(labelText: 'Model Name')),
              TextField(controller: _yearController, decoration: InputDecoration(labelText: 'Year'), keyboardType: TextInputType.number),
              TextField(controller: _mileageController, decoration: InputDecoration(labelText: 'Mileage (km/l)'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  if (_modelController.text.isEmpty || _yearController.text.isEmpty || _mileageController.text.isEmpty) {
                    ScaffoldMessenger.of(Navigator.of(context).overlay!.context).showSnackBar(SnackBar(content: Text('All fields are required!')));
                    return;
                  }

                  int? year = int.tryParse(_yearController.text);
double? mileage = double.tryParse(_mileageController.text);

if (year == null || year <= 0 || mileage == null || mileage <= 0) {
  ScaffoldMessenger.of(Navigator.of(context).overlay!.context).showSnackBar(
    SnackBar(content: Text('Enter valid numeric values!')),
  );
  return;
}


                  Vehicle newVehicle = Vehicle(
                    id: DateTime.now().millisecondsSinceEpoch,
                    model: _modelController.text,
                    year: year,
                    mileage: mileage,
                  );
                  await DatabaseHelper.insertVehicle(newVehicle);
                  _loadVehicles();
                  Navigator.pop(context);
                } catch (e) {
                  print('Error adding vehicle: $e');
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Vehicle List')),
        body: ListView.builder(
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            Vehicle vehicle = vehicles[index];
            return Card(
              color: _getVehicleColor(vehicle),
              child: ListTile(
                title: Text(vehicle.model),
                subtitle: Text('Year: ${vehicle.year}, Mileage: ${vehicle.mileage} km/l'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.black),
                  onPressed: () async {
                    await DatabaseHelper.deleteVehicle(vehicle.id);
                    setState(() {
                      vehicles.removeAt(index);
                    });
                  },
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: (){
            _showAddVehicleDialog(context);
            },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
