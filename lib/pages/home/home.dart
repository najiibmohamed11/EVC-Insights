import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sms_reader/pages/transactions/transactionPage%20.dart';
import 'package:sms_reader/providers/sms_provider.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with AutomaticKeepAliveClientMixin<Home> {
  @override
  bool get wantKeepAlive => true;
  Future<void>? _fetchSmsFuture;

  @override
  void initState() {
    super.initState();
    _fetchSmsFuture = _fetchSms();
  }

  Future<void> _fetchSms() async {
    final smsProvider = Provider.of<SmsProvider>(context, listen: false);
    await smsProvider.fetchSms();
  }

  List<BarChartGroupData> _generateBarGroups(SmsProvider smsProvider) {
    Map<String, double> data = {};
    DateTime now = DateTime.now();

    // Generate labels for the last 7 days
    List<String> dateLabels = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return DateFormat('MM/dd').format(date);
    });

    // Initialize data with zeroes for all 7 days
    for (String label in dateLabels) {
      data[label] = 0;
    }

    // Get the filtered messages from the SmsProvider
    List<Map<String, dynamic>> messagesToUse =
        smsProvider.getFilteredMessages();

    for (var message in messagesToUse) {
      DateTime messageDate = message['date'];

      // Only consider messages within the past 7 days
      if (messageDate.isAfter(now.subtract(Duration(days: 7))) ||
          messageDate.isAtSameMomentAs(now.subtract(Duration(days: 7)))) {
        String label = DateFormat('MM/dd').format(messageDate);

        // Sum the amounts for each day
        data[label] = (data[label] ?? 0) + message['amount'];
      }
    }

    // Generate the BarChartGroupData for each day
    return dateLabels.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: data[entry.value] ?? 0,
            color: Color(0xff13BC8D),
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(
        context); // Add this line to ensure AutomaticKeepAliveClientMixin works

    final smsProvider = Provider.of<SmsProvider>(context);

    return FutureBuilder(
      future: _fetchSmsFuture, // Use the stored future
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${smsProvider.calculateBalance().toStringAsFixed(2)}',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text('Total Balance', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 20),
              _buildFilterButtons(smsProvider),
              SizedBox(height: 20),
              _buildChart(smsProvider),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                      'Today', _calculateDailyAmount(smsProvider)),
                  _buildSummaryItem(
                      'This Week', _calculateWeeklyAmount(smsProvider)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterButtons(SmsProvider smsProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildFilterButton('All', smsProvider),
          _buildFilterButton('Sent', smsProvider),
          _buildFilterButton('Received', smsProvider),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter, SmsProvider smsProvider) {
    bool isSelected = smsProvider.currentFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          smsProvider.setFilter(filter);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xff13BC8D) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            filter,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChart(SmsProvider smsProvider) {
    List<BarChartGroupData> barGroups = _generateBarGroups(smsProvider);
    double maxY = barGroups.fold(
        0,
        (max, group) =>
            group.barRods.first.toY > max ? group.barRods.first.toY : max);

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                DateTime date =
                    DateTime.now().subtract(Duration(days: 6 - groupIndex));
                return BarTooltipItem(
                  '${DateFormat('MM/dd').format(date)}\n\$${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  DateTime date = DateTime.now()
                      .subtract(Duration(days: 6 - value.toInt()));
                  return Text(DateFormat('MM/dd').format(date),
                      style: TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('\$${value.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  double _calculateDailyAmount(SmsProvider smsProvider) {
    final now = DateTime.now();
    List<Map<String, dynamic>> messagesToUse =
        smsProvider.getFilteredMessages();
    return messagesToUse
        .where((msg) =>
            msg['date'].year == now.year &&
            msg['date'].month == now.month &&
            msg['date'].day == now.day)
        .fold(0, (sum, msg) => sum + (msg['amount']));
  }

  double _calculateWeeklyAmount(SmsProvider smsProvider) {
    final now = DateTime.now();
    List<Map<String, dynamic>> messagesToUse =
        smsProvider.getFilteredMessages();
    return messagesToUse
        .where((msg) =>
            msg['date'].isAfter(now.subtract(Duration(days: 7))) ||
            msg['date'].isAtSameMomentAs(now.subtract(Duration(days: 7))))
        .fold(0, (sum, msg) => sum + (msg['amount']));
  }

  Widget _buildSummaryItem(String title, double amount) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey)),
        SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}
