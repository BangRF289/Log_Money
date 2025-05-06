import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:last_money/models/database.dart';
import 'package:last_money/models/transaction_with_category.dart';
import 'package:last_money/utils/session_manager.dart';

class Transaksi extends StatefulWidget {
  final TransactionWithCategory? transactionWithCategory;
  const Transaksi({super.key, required this.transactionWithCategory});

  @override
  State<Transaksi> createState() => _TransaksiState();
}

class _TransaksiState extends State<Transaksi> {
  final AppDb database = AppDb();
  late int type;
  bool isExpense = true;
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController detailController = TextEditingController();
  Category? selectedCategory;

  String formatCurrency(int amount) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return currencyFormatter.format(amount);
  }

  Future insertTransaction(
      int amount, DateTime date, String nameDetail, int categoryId) async {
    DateTime now = DateTime.now();
    final userId = await SessionManager.getUserId(); // ✅ ambil user id

    if (userId == null) {
      print("❌ User ID not found in session");
      return;
    }

    final row = await database.into(database.transactions).insertReturning(
        TransactionsCompanion.insert(
            name: nameDetail,
            category_id: categoryId,
            transaction_date: date,
            amount: amount,
            user_id: userId,
            createdAt: now,
            updatedAt: now));

    print("✅ Data transaksi berhasil ditambahkan: $row");
  }

  Future<List<Category>> getAllCategory(int type, int userId) async {
    return await database.getAllCategoryRepo(type, userId);
  }

  Future updateTransaction(
    int transactionId,
    int amount,
    int categoryId,
    DateTime transactionDate,
    String nameDetail,
  ) async {
    return await database.updateTransactionRepo(
        transactionId, amount, categoryId, transactionDate, nameDetail);
  }

  @override
  void initState() {
    super.initState();
    if (widget.transactionWithCategory != null) {
      updateTransactionView(widget.transactionWithCategory!);
    } else {
      type = 2;
    }
  }

  void updateTransactionView(TransactionWithCategory transactionWithCategory) {
    setState(() {
      amountController.text =
          formatCurrency(transactionWithCategory.transaction.amount);
      detailController.text = transactionWithCategory.transaction.name;
      dateController.text = DateFormat("yyyy-MM-dd")
          .format(transactionWithCategory.transaction.transaction_date);
      type = transactionWithCategory.category.type;
      isExpense = (type == 2);
      selectedCategory = transactionWithCategory.category;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.transactionWithCategory != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? "Update Transaction" : "Add Transaction",
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Switch(
                    value: isExpense,
                    onChanged: (bool value) {
                      setState(() {
                        isExpense = value;
                        type = isExpense ? 2 : 1;
                        selectedCategory = null;
                      });
                    },
                    inactiveTrackColor: Colors.green[200],
                    inactiveThumbColor: Colors.green,
                    activeColor: Colors.red,
                  ),
                  Text(
                    isExpense ? 'Expense' : 'Income',
                    style: GoogleFonts.montserrat(fontSize: 14),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      border: UnderlineInputBorder(), labelText: "Amount"),
                  onChanged: (value) {
                    String rawValue = value.replaceAll(RegExp(r'[^\d]'), '');
                    setState(() {
                      amountController.text =
                          formatCurrency(int.tryParse(rawValue) ?? 0);
                      amountController.selection = TextSelection.fromPosition(
                        TextPosition(offset: amountController.text.length),
                      );
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Category",
                  style: GoogleFonts.montserrat(fontSize: 16),
                ),
              ),
              FutureBuilder<List<Category>>(
                future: SessionManager.getUserId().then((userId) {
                  if (userId == null) {
                    throw Exception("User ID tidak ditemukan");
                  }
                  return getAllCategory(type, userId);
                }),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("Tidak ada kategori"));
                  } else {
                    if (selectedCategory == null) {
                      selectedCategory = snapshot.data!.first;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: DropdownButton<Category>(
                        value: selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_downward),
                        items: snapshot.data!.map((Category item) {
                          return DropdownMenuItem<Category>(
                            value: item,
                            child: Text(item.name),
                          );
                        }).toList(),
                        onChanged: (Category? value) {
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  readOnly: true,
                  controller: dateController,
                  decoration: InputDecoration(
                      label: Text('Enter Date',
                          style: GoogleFonts.montserrat(fontSize: 16))),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2099));

                    if (pickedDate != null) {
                      setState(() {
                        dateController.text =
                            DateFormat('yyyy-MM-dd').format(pickedDate);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: detailController,
                  decoration: const InputDecoration(
                      border: UnderlineInputBorder(), labelText: "Detail"),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (amountController.text.isEmpty ||
                        dateController.text.isEmpty ||
                        detailController.text.isEmpty ||
                        selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Harap isi semua data"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (widget.transactionWithCategory == null) {
                      await insertTransaction(
                        int.tryParse(amountController.text
                                .replaceAll(RegExp(r'[^\d]'), '')) ??
                            0,
                        DateTime.parse(dateController.text),
                        detailController.text,
                        selectedCategory!.id,
                      );
                    } else {
                      await updateTransaction(
                        widget.transactionWithCategory!.transaction.id,
                        int.tryParse(amountController.text
                                .replaceAll(RegExp(r'[^\d]'), '')) ??
                            0,
                        selectedCategory!.id,
                        DateTime.parse(dateController.text),
                        detailController.text,
                      );
                    }

                    Future.delayed(Duration(milliseconds: 100), () {
                      if (mounted) {
                        Navigator.pop(context, true);
                      }
                    });
                  },
                  child: Text("Save"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
