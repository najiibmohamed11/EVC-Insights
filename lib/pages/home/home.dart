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
  String _timeFilter = 'Week'; // 'Week' or 'Month'

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
    if (_timeFilter == 'Week') {
      return _generateWeeklyBarGroups(smsProvider);
    } else {
      return _generateMonthlyBarGroups(smsProvider);
    }
  }

  List<BarChartGroupData> _generateWeeklyBarGroups(SmsProvider smsProvider) {
    Map<String, double> data = {};
    DateTime now = DateTime.now();

    // Generate labels for the last 7 days
    List<String> dateLabels = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      String dayName = DateFormat('EEE').format(date);
      return dayName;
    });

    // Initialize data with zeroes
    for (String label in dateLabels) {
      data[label] = 0;
    }

    List<Map<String, dynamic>> messagesToUse =
        smsProvider.getFilteredMessages();

    for (var message in messagesToUse) {
      DateTime messageDate = message['date'];
      if (messageDate.isAfter(now.subtract(Duration(days: 7)))) {
        String label = DateFormat('EEE').format(messageDate);
        data[label] = (data[label] ?? 0) + message['amount'];
      }
    }

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

List<BarChartGroupData> _generateMonthlyBarGroups(SmsProvider smsProvider) {
    Map<int, double> data = {};
    DateTime now = DateTime.now();

    // Get the first day of current month
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);

    // Get the last day of current month
    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Calculate number of 5-day groups needed for this month
    int numberOfGroups = (lastDayOfMonth.day / 5).ceil();

    // Initialize data with zeroes
    for (int i = 0; i < numberOfGroups; i++) {
      data[i] = 0;
    }

    List<Map<String, dynamic>> messagesToUse =
        smsProvider.getFilteredMessages();

    // Process only messages from current month
    for (var message in messagesToUse) {
      DateTime messageDate = message['date'];
      if (messageDate.year == now.year && messageDate.month == now.month) {
        // Calculate which 5-day group this message belongs to
        int dayOfMonth = messageDate.day;
        int groupIndex = (dayOfMonth - 1) ~/ 5;
        if (groupIndex < numberOfGroups) {
          data[groupIndex] = (data[groupIndex] ?? 0) + message['amount'];
        }
      }
    }

    return List.generate(numberOfGroups, (index) {
      // Calculate date range for this group
      DateTime startDate = firstDayOfMonth.add(Duration(days: index * 5));
      DateTime endDate = startDate.add(Duration(days: 4));
      if (endDate.month != firstDayOfMonth.month) {
        endDate = lastDayOfMonth;
      }

      // Format the date range label
      String label =
          '${DateFormat('dd').format(startDate)}-${DateFormat('dd').format(endDate)}';

      // Check if this group is in the future
      bool isFutureGroup = startDate.isAfter(now);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: isFutureGroup ? 0 : (data[index] ?? 0),
            color: isFutureGroup
                ? Colors.grey.withOpacity(0.3)
                : Color(0xff13BC8D),
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

@override
  Widget build(BuildContext context) {
    super.build(context);
    final smsProvider = Provider.of<SmsProvider>(context);

    return FutureBuilder(
      future: _fetchSmsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${smsProvider.calculateBalance().toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text('Total Balance',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  _buildTimeFilterButton(),
                ],
              ),
              SizedBox(height: 20),
              _buildTransactionFilterButtons(smsProvider),
              SizedBox(height: 20),
              _buildChart(smsProvider),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                      'Today', _calculateDailyAmount(smsProvider)),
                  _buildSummaryItem(
                      _timeFilter == 'Week' ? 'This Week' : 'This Month',
                      _timeFilter == 'Week'
                          ? _calculateWeeklyAmount(smsProvider)
                          : _calculateMonthlyAmount(smsProvider)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeFilterButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _timeFilter,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          isDense: true,
          items: ['Week', 'Month'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _timeFilter = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTransactionFilterButtons(SmsProvider smsProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTransactionFilterButton('Sent', smsProvider),
          _buildTransactionFilterButton('Received', smsProvider),
        ],
      ),
    );
  }

  Widget _buildTransactionFilterButton(String filter, SmsProvider smsProvider) {
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
                if (_timeFilter == 'Week') {
                  DateTime date =
                      DateTime.now().subtract(Duration(days: 6 - groupIndex));
                  return BarTooltipItem(
                    '${DateFormat('MM/dd').format(date)}\n\$${rod.toY.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white),
                  );
                } else {
                  DateTime now = DateTime.now();
                  DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
                  DateTime startDate =
                      firstDayOfMonth.add(Duration(days: groupIndex * 5));
                  DateTime endDate = startDate.add(Duration(days: 4));

                  if (endDate.month != firstDayOfMonth.month) {
                    endDate = DateTime(now.year, now.month + 1, 0);
                  }

                  return BarTooltipItem(
                    '${DateFormat('MM/dd').format(startDate)}-${DateFormat('MM/dd').format(endDate)}\n\$${rod.toY.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white),
                  );
                }
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (_timeFilter == 'Week') {
                    DateTime date = DateTime.now()
                        .subtract(Duration(days: 6 - value.toInt()));
                    return Text(DateFormat('EEE').format(date),
                        style: TextStyle(fontSize: 10));
                  } else {
                    DateTime now = DateTime.now();
                    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
                    DateTime startDate =
                        firstDayOfMonth.add(Duration(days: value.toInt() * 5));

                    return Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Text(
                        DateFormat('d').format(startDate),
                        style: TextStyle(
                          fontSize: 10,
                          color: startDate.isAfter(now)
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    );
                  }
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
            msg['date'].isAfter(now.subtract(Duration(days: 7))))
        .fold(0, (sum, msg) => sum + (msg['amount']));
  }

  double _calculateMonthlyAmount(SmsProvider smsProvider) {
    final now = DateTime.now();
    List<Map<String, dynamic>> messagesToUse =
        smsProvider.getFilteredMessages();
    return messagesToUse
        .where((msg) => msg['date'].isAfter(now.subtract(Duration(days: 30))))
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
