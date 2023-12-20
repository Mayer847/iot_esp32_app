import 'dart:io';
//import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DatabaseService {
  // Define the ValueNotifier
  //final ValueNotifier<bool> dataUpdatedNotifier = ValueNotifier(false);
  static final DatabaseService instance = DatabaseService._init();
  final String tableIotNotify = 'iot_esp32_app';

  static Database? _database;

  DatabaseService._init();

  Future<void> insertData(double temperature, double humidity) async {
    final db = await instance.database;
    final iotNotify = IotNotify(
      id: 0, // this will be auto-incremented by SQLite
      time: DateTime.now().toIso8601String(),
      temperature: temperature,
      humidity: humidity,
    );
    await db.insert(tableIotNotify, iotNotify.toJson());
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('iot_esp32_app_db.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final textType = 'TEXT NOT NULL';
    final realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE $tableIotNotify ( 
  ${IotNotifyFields.id} $idType, 
  ${IotNotifyFields.time} $textType,
  ${IotNotifyFields.temperature} $realType,
  ${IotNotifyFields.humidity} $realType
  )
''');
  }

  Future<IotNotify> create(IotNotify iotNotify) async {
    final db = await instance.database;

    await db.insert(
        tableIotNotify, iotNotify.toJson()); //removed unused final id = blabla

    return iotNotify; // Return the iotNotify object directly
  }

  Future<List<Map<String, dynamic>>> readAllNotes() async {
    final db = await instance.database;

    final result = await db.query(tableIotNotify, orderBy: "time DESC");

    return result;
  }

  Future<void> exportToExcel() async {
    // print('exportToExcel called');
    List<Map<String, dynamic>> data = await readAllNotes();

    var excel = Excel.createExcel();
    Sheet sheet = excel['SheetName'];

    // Create the header row
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Time'),
      TextCellValue('Temperature'),
      TextCellValue('Humidity')
    ]);

    // Add the data rows
    for (var item in data) {
      sheet.appendRow([
        item['id'],
        item['time'],
        item['temperature'],
        item['humidity'],
      ]);
    }

    // Save the Excel file in the Downloads folder
    if (await Permission.storage.request().isGranted) {
      // print('Permission granted');
      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        downloadsDirectory = await getExternalStorageDirectory();
      } else {
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      // Get the current date and time
      DateTime now = DateTime.now();
      // Format the date and time as a string
      String formattedDate =
          "${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}";

      String path = downloadsDirectory!.path;
      // Include the timestamp in the file name
      String fileName = 'iot_esp32_app_data_$formattedDate.xlsx';

      print('File path: $path/$fileName');

      var fileBytes = await excel.encode();
      File("$path/$fileName")
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);

      // Delete all data from the database after exporting
      await deleteAllData();
      // Notify listeners that the data has been updated
      //dataUpdatedNotifier.value = true;
    } else {
      print('Permission not granted');
    }
  }

  Future<void> deleteAllData() async {
    final db = await instance.database;
    await db.delete(tableIotNotify);
  }
}

class IotNotify {
  final int id;
  final String time;
  final double temperature;
  final double humidity;

  IotNotify({
    required this.id,
    required this.time,
    required this.temperature,
    required this.humidity,
  });

  Map<String, dynamic> toJson() => {
        if (id != 0) 'id': id,
        'time': time,
        'temperature': temperature,
        'humidity': humidity,
      };

  factory IotNotify.fromJson(Map<String, dynamic> json) => IotNotify(
        id: json['id'],
        time: json['time'],
        temperature: json['temperature'],
        humidity: json['humidity'],
      );
}

class IotNotifyFields {
  static final List<String> values = [
    /// Add all fields
    id, time, temperature, humidity
  ];

  static final String id = 'id';
  static final String time = 'time';
  static final String temperature = 'temperature';
  static final String humidity = 'humidity';
}
