import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:last_money/models/database.dart';
import 'package:last_money/utils/session_manager.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final AppDb database = AppDb();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  final List<String> questionPresets = [
    "pengeluaran bulan ini",
    "pemasukan bulan ini",
    "pengeluaran tahun ini",
    "pemasukan tahun ini",
    "saldo",
    "fitur",
    "antara 01/01/2024 dan 31/01/2024",
  ];

  String? selectedQuestion;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(String text, {required bool fromUser}) {
    setState(() {
      _messages.add({'text': text, 'fromUser': fromUser});
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _handleUserMessage(String message) async {
    _addMessage(message, fromUser: true);
    final lower = message.toLowerCase();
    final now = DateTime.now();

    try {
      final userId = await SessionManager.getUserId();
      if (userId == null) {
        _addMessage("❌ User belum login.", fromUser: false);
        return;
      }

      if (lower.contains("pengeluaran") && lower.contains("bulan ini")) {
        final transactions = await database.getTransactionsByMonthByUser(
            userId, now.month, now.year);
        final pengeluaran =
            transactions.where((e) => e.category.type == 2).toList();
        if (pengeluaran.isEmpty) {
          _addMessage("Tidak ada data pengeluaran bulan ini.", fromUser: false);
        } else {
          final detail = pengeluaran
              .map((t) =>
                  "- ${t.transaction.name}: ${_formatRupiah(t.transaction.amount)}")
              .join("\n");
          _addMessage("Pengeluaran bulan ini:\n$detail", fromUser: false);
        }
      } else if (lower.contains("pemasukan") && lower.contains("bulan ini")) {
        final transactions = await database.getTransactionsByMonthByUser(
            userId, now.month, now.year);
        final pemasukan =
            transactions.where((e) => e.category.type == 1).toList();
        if (pemasukan.isEmpty) {
          _addMessage("Tidak ada data pemasukan bulan ini.", fromUser: false);
        } else {
          final detail = pemasukan
              .map((t) =>
                  "- ${t.transaction.name}: ${_formatRupiah(t.transaction.amount)}")
              .join("\n");
          _addMessage("Pemasukan bulan ini:\n$detail", fromUser: false);
        }
      } else if (lower.contains("pengeluaran") && lower.contains("tahun ini")) {
        final list = await database.getAllTransactionsByUser(userId);
        final filtered = list.where((e) =>
            e.transaction.transaction_date.year == now.year &&
            e.category.type == 2);
        final total =
            filtered.fold<int>(0, (sum, e) => sum + e.transaction.amount);
        _addMessage(
            "Total pengeluaran tahun ini adalah ${_formatRupiah(total)}.",
            fromUser: false);
      } else if (lower.contains("pemasukan") && lower.contains("tahun ini")) {
        final list = await database.getAllTransactionsByUser(userId);
        final filtered = list.where((e) =>
            e.transaction.transaction_date.year == now.year &&
            e.category.type == 1);
        final total =
            filtered.fold<int>(0, (sum, e) => sum + e.transaction.amount);
        _addMessage("Total pemasukan tahun ini adalah ${_formatRupiah(total)}.",
            fromUser: false);
      } else if (lower.contains("saldo") || lower.contains("balance")) {
        final transactions = await database.getAllTransactionsByUser(userId);
        final totalIncome = transactions
            .where((e) => e.category.type == 1)
            .fold<int>(0, (sum, e) => sum + e.transaction.amount);
        final totalExpense = transactions
            .where((e) => e.category.type == 2)
            .fold<int>(0, (sum, e) => sum + e.transaction.amount);
        final balance = totalIncome - totalExpense;
        _addMessage(
          "Saldo saat ini: ${_formatRupiah(balance)}\n"
          "Pemasukan: ${_formatRupiah(totalIncome)}\n"
          "Pengeluaran: ${_formatRupiah(totalExpense)}",
          fromUser: false,
        );
      } else if (lower.contains("antara") && lower.contains("dan")) {
        final dateRegex = RegExp(r'(\d{2}/\d{2}/\d{4})');
        final matches = dateRegex.allMatches(message).toList();

        if (matches.length == 2) {
          try {
            final startDate =
                DateFormat('dd/MM/yyyy').parse(matches[0].group(0)!);
            final endDate =
                DateFormat('dd/MM/yyyy').parse(matches[1].group(0)!);
            final transactions =
                await database.getAllTransactionsByUser(userId);
            final filtered = transactions.where((t) {
              final d = t.transaction.transaction_date;
              return d.isAfter(startDate.subtract(const Duration(days: 1))) &&
                  d.isBefore(endDate.add(const Duration(days: 1)));
            }).toList();

            if (filtered.isEmpty) {
              _addMessage("Tidak ada transaksi antara tanggal tersebut.",
                  fromUser: false);
            } else {
              final detail = filtered
                  .map((t) =>
                      "- ${DateFormat('dd MMM yyyy').format(t.transaction.transaction_date)} | ${t.transaction.name}: ${_formatRupiah(t.transaction.amount)}")
                  .join("\n");
              _addMessage("Transaksi:\n$detail", fromUser: false);
            }
          } catch (e) {
            _addMessage("Format tanggal salah. Gunakan dd/MM/yyyy.",
                fromUser: false);
          }
        } else {
          _addMessage(
              "Format tanggal tidak dikenali. Contoh: antara 01/01/2024 dan 31/01/2024",
              fromUser: false);
        }
      } else if (lower.contains("fitur")) {
        _addMessage(
          "Fitur aplikasi:\n- Tambah transaksi\n- Lihat kategori\n- Grafik keuangan\n- ChatBot keuangan 💬",
          fromUser: false,
        );
      } else {
        _addMessage("Tunggu sebentar...", fromUser: false);
        final aiResponse = await _getAIResponse(message);
        _addMessage(aiResponse ?? "Asisten tidak dapat menjawab saat ini.",
            fromUser: false);
      }
    } catch (e) {
      _addMessage("Terjadi kesalahan: $e", fromUser: false);
    }
  }

  Future<String?> _getAIResponse(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey');

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text":
                  "Kamu adalah asisten keuangan yang membantu menjawab pertanyaan pengguna terkait keuangan pribadi."
            },
            {"text": prompt}
          ]
        }
      ]
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['candidates'][0]['content']['parts'][0]['text'];
      } else {
        print("❌ Error ${response.statusCode}: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Exception: $e");
      return null;
    }
  }

  String _formatRupiah(int amount) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
        .format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("ChatBot Asisten"),
        backgroundColor: Colors.green[600],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['fromUser'];
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.green[100] : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      msg['text'],
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),

          // 👇 Dropdown dan Input Field di bagian bawah
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: "Pesan cepat",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.flash_on),
                  ),
                  value: selectedQuestion,
                  items: questionPresets
                      .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedQuestion = null);
                      _handleUserMessage(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 6),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Tulis pesan...",
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _handleUserMessage(value.trim());
                            _controller.clear();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.green),
                      onPressed: () {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) {
                          _handleUserMessage(text);
                          _controller.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
