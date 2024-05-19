import 'package:flutter/material.dart';
import 'add.dart';
import 'edit_expense.dart';
import 'database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future main() async {
  // Initialize FFI
  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _expenses;
  late Future<double> _totalExpenses;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  void _fetchExpenses() {
    setState(() {
      _expenses = DatabaseHelper.instance.getExpenses();
      _totalExpenses = _calculateTotalExpenses();
    });
  }

  Future<double> _calculateTotalExpenses() async {
    final expenses = await DatabaseHelper.instance.getExpenses();
    double total = 0.0;
    for (var expense in expenses) {
      total += double.tryParse(expense['amount']) ?? 0.0;
    }
    return total;
  }

  void _deleteExpense(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    _fetchExpenses();
  }

  void _editExpense(Map<String, dynamic> expense) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => EditExpensePage(expense: expense)),
    );
    _fetchExpenses(); // Refresh the list after returning from EditExpensePage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24),
        title: const Text('Expense Tracker'),
      ),
      body: Column(
        children: <Widget>[
          FutureBuilder<double>(
            future: _totalExpenses,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(
                    child: Text('Error calculating total expenses'));
              } else {
                final total = snapshot.data ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Total Expenses: \$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                );
              }
            },
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _expenses,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching expenses'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No expenses added yet'));
                } else {
                  final expenses = snapshot.data!;
                  return ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return ListTile(
                        leading:
                            const Icon(Icons.attach_money, color: Colors.red),
                        title: Text(
                          expense['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Category: ${expense['category']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '\$${expense['amount']}',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (String result) {
                                if (result == 'Edit') {
                                  _editExpense(expense);
                                } else if (result == 'Delete') {
                                  _deleteExpense(expense['id']);
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'Edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'Delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddExpensePage()),
          );
          _fetchExpenses(); // Refresh the list after returning from AddExpensePage
        },
        backgroundColor: Colors.red,
        tooltip: 'Add',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
