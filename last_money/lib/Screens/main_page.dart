import 'package:calendar_appbar/calendar_appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:last_money/Screens/catagory_page.dart';

import 'package:last_money/Screens/home_page.dart';
import 'package:last_money/Screens/transaction_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late DateTime selectedDate;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    currentIndex = 0;
  }

  void updateView(int index, {DateTime? date}) {
    setState(() {
      if (date != null) {
        selectedDate = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
        print("📆 Tanggal berubah ke: $selectedDate");
      }
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (currentIndex == 0)
          ? CalendarAppBar(
              backButton: false,
              locale: 'id',
              accent: Colors.green,
              onDateChanged: (value) {
                print("SELECTED DATE: $value");
                updateView(0, date: value);
              },
              firstDate: DateTime.now().subtract(const Duration(days: 140)),
              lastDate: DateTime.now(),
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(200),
              child: Container(
                color: Colors.green,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 25, horizontal: 16),
                  child: Text(
                    "Categories",
                    style: GoogleFonts.montserrat(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: Visibility(
        visible: currentIndex == 0,
        child: FloatingActionButton(
          heroTag: 'main-fab',
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const Transaksi(
                        transactionWithCategory: null,
                      )),
            );

            if (result == true) {
              setState(() {}); // Refresh MainPage/HomePage
            }
          },
          backgroundColor: const Color.fromARGB(255, 12, 198, 164),
          child: const Icon(Icons.add),
        ),
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          HomePage(
              key: ValueKey(selectedDate),
              selectedDate: selectedDate), // Paksa rebuild saat tanggal berubah
          const CategoryPage(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
                onPressed: () {
                  updateView(0, date: DateTime.now());
                },
                icon: const Icon(Icons.home)),
            const SizedBox(width: 20),
            IconButton(
                onPressed: () {
                  updateView(1);
                },
                icon: const Icon(Icons.list))
          ],
        ),
      ),
    );
  }
}
