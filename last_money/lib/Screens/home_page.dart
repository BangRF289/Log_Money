import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:last_money/Screens/chat_bot_page.dart';
import 'package:last_money/Screens/login_page.dart';
import 'package:last_money/Screens/transaction_page.dart';
import 'package:last_money/models/database.dart';
import 'package:last_money/models/transaction_with_category.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:last_money/utils/session_manager.dart';

class HomePage extends StatefulWidget {
  final DateTime selectedDate;
  const HomePage({super.key, required this.selectedDate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppDb database = AppDb();
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await SessionManager.getUserId();
    setState(() {
      userId = id;
    });
  }

  Widget build(BuildContext context) {
    int selectedMonth = widget.selectedDate.month;
    int selectedYear = widget.selectedDate.year;

    print("📆 Tanggal terpilih di HomePage: ${widget.selectedDate}");

    return Stack(
      children: [
        SingleChildScrollView(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await SessionManager.clearSession();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 56, 54, 54),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StreamBuilder<int>(
                          key: ValueKey("income-$selectedMonth-$selectedYear"),
                          stream: (userId == null)
                              ? const Stream.empty()
                              : database.watchTotalIncomeByUser(
                                  userId!, selectedMonth, selectedYear),
                          builder: (context, snapshot) {
                            int totalIncome = snapshot.data ?? 0;
                            return _buildIncomeExpenseWidget(
                              icon: Icons.download,
                              label: "Income",
                              color: Colors.green,
                              amount: NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp',
                                decimalDigits: 0,
                              ).format(totalIncome),
                            );
                          },
                        ),
                        StreamBuilder<int>(
                          key: ValueKey("expense-$selectedMonth-$selectedYear"),
                          stream: (userId == null)
                              ? const Stream.empty()
                              : database.watchTotalExpenseByUser(
                                  userId!, selectedMonth, selectedYear),
                          builder: (context, snapshot) {
                            int totalExpense = snapshot.data ?? 0;
                            return _buildIncomeExpenseWidget(
                              icon: Icons.upload,
                              label: "Expense",
                              color: Colors.red,
                              amount: NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp',
                                decimalDigits: 0,
                              ).format(totalExpense),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                TotalExpenseIncomeChartWidget(
                  selectedMonth: selectedMonth,
                  selectedYear: selectedYear,
                  userId: userId,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Transaction",
                    style: GoogleFonts.montserrat(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                StreamBuilder<List<TransactionWithCategory>>(
                  stream: (userId == null)
                      ? const Stream.empty()
                      : database.getTransactionsByDateByUser(
                          widget.selectedDate, userId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final transaction =
                                snapshot.data![index].transaction;
                            final category = snapshot.data![index].category;

                            String formattedAmount = NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp',
                              decimalDigits: 0,
                            ).format(transaction.amount);

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Card(
                                elevation: 10,
                                child: ListTile(
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          await database.deleteTransactionRepo(
                                              transaction.id);
                                          setState(() {});
                                        },
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                      ),
                                      SizedBox(width: 10),
                                      IconButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => Transaksi(
                                                transactionWithCategory:
                                                    snapshot.data![index],
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.edit,
                                            color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    formattedAmount,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                      "${category.name} (${transaction.name})"),
                                  leading: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Icon(
                                      (category.type == 2)
                                          ? Icons.upload
                                          : Icons.download,
                                      color: (category.type == 2)
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return Center(child: Text("Tidak Ada Data"));
                      }
                    }
                  },
                ),
                SizedBox(height: 60),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.blueAccent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatBotPage()),
              );
            },
            child: const Icon(Icons.chat),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseWidget({
    required IconData icon,
    required String label,
    required Color color,
    required String amount,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ✅ FIXED: Implement TotalExpenseIncomeChartWidget
class TotalExpenseIncomeChartWidget extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  final int? userId;

  const TotalExpenseIncomeChartWidget({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.userId,
  });

  @override
  _TotalExpenseIncomeChartWidgetState createState() =>
      _TotalExpenseIncomeChartWidgetState();
}

class _TotalExpenseIncomeChartWidgetState
    extends State<TotalExpenseIncomeChartWidget> {
  final AppDb database = AppDb();
  bool _showChart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _showChart = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: (widget.userId == null)
          ? const Stream.empty()
          : database.watchTotalExpenseByUser(
              widget.userId!, widget.selectedMonth, widget.selectedYear),
      builder: (context, expenseSnapshot) {
        return StreamBuilder<int>(
          stream: (widget.userId == null)
              ? const Stream.empty()
              : database.watchTotalIncomeByUser(
                  widget.userId!, widget.selectedMonth, widget.selectedYear),
          builder: (context, incomeSnapshot) {
            if (!expenseSnapshot.hasData || !incomeSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final totalExpense = expenseSnapshot.data ?? 0;
            final totalIncome = incomeSnapshot.data ?? 0;

            if (totalExpense == 0 && totalIncome == 0) {
              return const Center(child: Text("Tidak ada data yang tersedia"));
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 200,
                child: _showChart
                    ? PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: totalExpense.toDouble(),
                              color: Colors.red,
                              title: 'EXP',
                            ),
                            PieChartSectionData(
                              value: totalIncome.toDouble(),
                              color: Colors.green,
                              title: 'INC',
                            ),
                          ],
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            );
          },
        );
      },
    );
  }
}
