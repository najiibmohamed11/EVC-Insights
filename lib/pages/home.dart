import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final SmsQuery _query = SmsQuery();

  List<Map<String, dynamic>> allFormattedMessages = [];
  List<Map<String, dynamic>> sentMessages = [];
  List<Map<String, dynamic>> receivedMessages = [];
  double balance = 0;
  List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String currentFilter = 'All'; // 'All', 'Sent', or 'Received'

  @override
  void initState() {
    super.initState();
    _fetchSms();
  }

  Future<void> _fetchSms() async {
    var permission = await Permission.sms.status;
    if (!permission.isGranted) {
      permission = await Permission.sms.request();
    }

    if (permission.isGranted) {
      try {
        final messages = await _query.querySms(address: '192');
        setState(() {
          allFormattedMessages = _processMessages(messages);
          sentMessages = allFormattedMessages.where((msg) => msg['type'] == 'sent').toList();
          receivedMessages = allFormattedMessages.where((msg) => msg['type'] == 'received').toList();
          balance = allFormattedMessages.isNotEmpty
              ? allFormattedMessages.first['remainer']
              : 0;
        });
      } catch (e) {
        print('Error fetching SMS: $e');
      }
    } else {
      print('SMS permission denied');
    }
  }

  List<Map<String, dynamic>> _processMessages(List<SmsMessage> messages) {
    return messages.map((message) {
      final body = message.body ?? '';
      final isReceived = body.contains("waxaad \$");
      final amount = double.tryParse(
              RegExp(r'\$(\d+(\.\d+)?)').firstMatch(body)?.group(1) ?? '0') ??
          0;
      final phoneNumber = RegExp(r'(\d{9,})').firstMatch(body)?.group(1) ?? '';
      
      final dateMatch = RegExp(r'Tar: (\d{2}/\d{2}/\d{2})').firstMatch(body);
      DateTime date;
      if (dateMatch != null) {
        final dateString = dateMatch.group(1)!;
        date = DateFormat('dd/MM/yy').parse(dateString);
      } else {
        date = message.date ?? DateTime.now();
      }
      
      final remainer = double.tryParse(
              RegExp(r'waa \$(\d+(\.\d+)?)').firstMatch(body)?.group(1) ??
                  '0') ??
          0;

      return {
        'type': isReceived ? 'received' : 'sent',
        'amount': amount,
        'phoneNumber': phoneNumber,
        'date': date,
        'remainer': remainer,
      };
    }).toList();
  }

  List<BarChartGroupData> _generateBarGroups() {
    Map<int, double> data = {};
    for (int i = 0; i < 7; i++) {
      data[i] = 0;
    }

    DateTime now = DateTime.now();
    DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));

    List<Map<String, dynamic>> messagesToUse;
    switch (currentFilter) {
      case 'Sent':
        messagesToUse = sentMessages;
        break;
      case 'Received':
        messagesToUse = receivedMessages;
        break;
      default:
        messagesToUse = allFormattedMessages;
    }

    for (var message in messagesToUse) {
      DateTime messageDate = message['date'];
      if (messageDate.isAfter(weekStart) ||
          messageDate.isAtSameMomentAs(weekStart)) {
        int dayIndex = messageDate.weekday - 1;
        data[dayIndex] = (data[dayIndex] ?? 0) + message['amount'];
      }
    }

    return data.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Colors.blue[300],
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildChart() {
    List<BarChartGroupData> barGroups = _generateBarGroups();
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
                return BarTooltipItem(
                  '${weekDays[groupIndex]}\n\$${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(weekDays[value.toInt()],
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
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Weekly Transaction Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${balance.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Balance',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 20),
            _buildFilterButtons(),
            SizedBox(height: 20),
            _buildChart(),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Today', _calculateDailyAmount()),
                _buildSummaryItem('This Week', _calculateWeeklyAmount()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildFilterButton('All'),
          _buildFilterButton('Sent'),
          _buildFilterButton('Received'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    bool isSelected = currentFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            currentFilter = filter;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
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

  double _calculateDailyAmount() {
    final now = DateTime.now();
    List<Map<String, dynamic>> messagesToUse = _getFilteredMessages();
    return messagesToUse
        .where((msg) =>
            msg['date'].year == now.year &&
            msg['date'].month == now.month &&
            msg['date'].day == now.day)
        .fold(0, (sum, msg) => sum + (msg['amount'] as double));
  }

  double _calculateWeeklyAmount() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    List<Map<String, dynamic>> messagesToUse = _getFilteredMessages();
    return messagesToUse
        .where((msg) =>
            msg['date'].isAfter(weekStart) ||
            msg['date'].isAtSameMomentAs(weekStart))
        .fold(0, (sum, msg) => sum + (msg['amount'] as double));
  }

  List<Map<String, dynamic>> _getFilteredMessages() {
    switch (currentFilter) {
      case 'Sent':
        return sentMessages;
      case 'Received':
        return receivedMessages;
      default:
        return allFormattedMessages;
    }
  }
}