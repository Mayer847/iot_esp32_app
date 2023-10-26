import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iot_esp32_app/services/database_service.dart';

class DatabasePage extends StatefulWidget {
  @override
  _DatabasePageState createState() => _DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 4), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Database'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.archive),
            onPressed: () async {
              await databaseService.exportToExcel();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: databaseService.readAllNotes(),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return ListView.builder(
              itemCount: snapshot.data?.length ?? 0, // Use ?. to access length
              itemBuilder: (BuildContext context, int index) {
                Map<String, dynamic>? item =
                    snapshot.data?[index]; // Use ?. to access []
                if (item != null) {
                  return ListTile(
                    title: Text(
                        'Temperature: ${item['temperature']}°C, Humidity: ${item['humidity']}%'),
                    subtitle: Text('Time: ${item['time']}'),
                  );
                } else {
                  return SizedBox
                      .shrink(); // Return an empty widget if item is null
                }
              },
            );
          }
        },
      ),
    );
  }
}
