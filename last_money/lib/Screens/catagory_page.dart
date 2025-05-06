import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_money/models/database.dart';
import 'package:last_money/utils/session_manager.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool isExpense = true;
  final AppDb database = AppDb();
  TextEditingController categoryNameController = TextEditingController();

  Future insert(String name, int type) async {
    DateTime now = DateTime.now();
    int? userId = await SessionManager.getUserId(); // 🔥 ambil user id

    if (userId == null) {
      print("User ID tidak ditemukan!");
      return;
    }

    final row = await database.into(database.categories).insertReturning(
          CategoriesCompanion.insert(
            name: name,
            type: type,
            user_id: userId,
            created_at: now,
            updated_at: now,
          ),
        );

    print(row);
  }

  Future<List<Category>> getAllCategory(int type) async {
    int? userId = await SessionManager.getUserId();
    if (userId == null) return [];

    return await database.getAllCategoryByUser(type, userId);
  }

  Future update(int categoryId, String newName) async {
    return await database.updateCategoryRepo(categoryId, newName);
  }

  void openDialog(Category? category) {
    if (category != null) {
      categoryNameController.text = category.name;
    }
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    Text(
                      (isExpense) ? "Add Expense" : "Add Income",
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: (isExpense) ? Colors.red : Colors.green),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: categoryNameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Name",
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (category == null) {
                          insert(
                              categoryNameController.text, isExpense ? 2 : 1);
                        } else {
                          update(category.id, categoryNameController.text);
                        }

                        Navigator.of(context, rootNavigator: true)
                            .pop('dialog');
                        setState(() {});
                        categoryNameController.clear();
                      },
                      child: Text(
                        "Save",
                        style: GoogleFonts.montserrat(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Switch(
                  value: isExpense,
                  onChanged: (bool value) {
                    setState(() {
                      isExpense = value;
                    });
                  },
                  inactiveTrackColor: Colors.green[200],
                  inactiveThumbColor: Colors.green,
                  activeColor: Colors.red,
                ),
                IconButton(
                    onPressed: () {
                      openDialog(null);
                    },
                    icon: const Icon(Icons.add))
              ],
            ),
          ),
          FutureBuilder<List<Category>>(
            future: getAllCategory(isExpense ? 2 : 1),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          elevation: 10,
                          child: ListTile(
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    database.deleteCategoryRepo(
                                        snapshot.data![index].id);
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.delete),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                    onPressed: () {
                                      openDialog(snapshot.data![index]);
                                    },
                                    icon: const Icon(Icons.edit))
                              ],
                            ),
                            title: Text(snapshot.data![index].name),
                            leading: Container(
                              child: (isExpense)
                                  ? const Icon(Icons.upload, color: Colors.red)
                                  : const Icon(
                                      Icons.download,
                                      color: Colors.green,
                                    ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ),
                      );
                    });
              } else {
                return const Center(
                  child: Text("No data available"),
                );
              }
            },
          ),
        ],
      )),
    );
  }
}
