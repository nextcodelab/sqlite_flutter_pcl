import 'package:flutter/material.dart';
import 'package:sqlite_flutter_pcl/sqlite_flutter_pcl.dart';
import 'path_helper.dart';
import 'sql_model.dart';

class ViewSample extends StatefulWidget {
  const ViewSample({super.key});

  @override
  State<ViewSample> createState() => _ViewSampleState();
}

class _ViewSampleState extends State<ViewSample> {
  List<ISQLiteItem> sampleItems = [];
  int updateCounter = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30,),
        OutlinedButton(
          onPressed: () async {
            sampleItems = [
              SqlModel(title: 'Sample Title 1', value: 'Sample Value 1'),
              SqlModel(title: 'Sample Title 2', value: 'Sample Value 2'),
              SqlModel(title: 'Sample Title 3', value: 'Sample Value 3'),
              SqlModel(title: 'Sample Title 4', value: 'Sample Value 4'),
              SqlModel(title: 'Sample Title 5', value: 'Sample Value 5'),
            ];
            final databasePath = await getTemporaryDatabasePath();
            final connection = SQLiteConnection(path: databasePath);
            connection.createTable(SqlModel());
            for (var item in sampleItems) {
              await connection.insert(item); // Await here
            }
            final retrievedItems = await connection.toList(SqlModel());
            setState(() {
              sampleItems = retrievedItems;
            });
          },
          child: const Text('Insert Items'),
        ),
        OutlinedButton(
          onPressed: () async {
            final databasePath = await getTemporaryDatabasePath();
            final connection = SQLiteConnection(path: databasePath);
            final retrievedItems = await connection.toList(SqlModel());

            setState(() {
              sampleItems = retrievedItems; // Update the list after retrieval
            });
          },
          child: const Text('Retrieve Items'),
        ),
        OutlinedButton(
          onPressed: () async {
            final databasePath = await getTemporaryDatabasePath();
            final connection = SQLiteConnection(path: databasePath);
            var retrievedItems = await connection.toList(SqlModel());
            await connection.deleteAll(retrievedItems);
            retrievedItems = await connection.toList(SqlModel());
            setState(() {
              sampleItems = retrievedItems; // Update the list after retrieval
            });
          },
          child: const Text('Delete Items'),
        ),
        OutlinedButton(
          onPressed: () async {
            final databasePath = await getTemporaryDatabasePath();
            final connection = SQLiteConnection(path: databasePath);
            var retrievedItems = await connection.toList(SqlModel());
            for (var item in retrievedItems) {
              (item as SqlModel).value = 'Updated $updateCounter';
              await connection.update(item);
            }
            updateCounter++;

            retrievedItems = await connection.toList(SqlModel());
            setState(() {
              sampleItems = retrievedItems; // Update the list after retrieval
            });
          },
          child: const Text('Update Items'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sampleItems.length,
            itemBuilder: (context, index) {
              var item = sampleItems[index] as SqlModel;
              return ListTile(
                title: Text(item.title!),
                subtitle: Text(item.value!),
              );
            },
          ),
        ),
      ],
    );
  }
}
