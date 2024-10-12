import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart'; // For date formatting

class DetailsChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactions; // Transactions list
  DetailsChartWidget({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Filter and calculate the totals for sent and received transactions
    double totalSent = 0.0;
    double totalReceived = 0.0;

    for (var transaction in transactions) {
      double amount = transaction['amount'] ?? 0.0;
      if (transaction['type'] == 'sent') {
        totalSent += amount;
      } else if (transaction['type'] == 'received') {
        totalReceived += amount;
      }
    }

    // Calculate total expenses
    double totalExpenses = totalSent + totalReceived;

    // Format the date range (from first to last transaction)
    String startDate = DateFormat('d MMM yyyy').format(
      _parseDate(transactions.last['date']),
    ); // Last transaction date
    String endDate = DateFormat('d MMM yyyy').format(
      _parseDate(transactions.first['date']),
    ); // First transaction date

    // Data for the pie chart
    Map<String, double> dataMap = {
      "Sent": totalSent,
      "Received": totalReceived,
    };

    // Color map for the pie chart
    final colorList = <Color>[
      Colors.redAccent,
      Colors.greenAccent,
    ];

    // Round the values to 2 decimal places
    String roundedTotalSent = totalSent.toStringAsFixed(2);
    String roundedTotalReceived = totalReceived.toStringAsFixed(2);
    String roundedTotalExpenses = totalExpenses.toStringAsFixed(2);

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expenses title and total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expenses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$startDate - $endDate', // Dynamic date range
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Text(
                '\$$roundedTotalExpenses', // Dynamic total amount (rounded)
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Pie chart
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: PieChart(
                  dataMap: dataMap,
                  chartType: ChartType.ring,
                  colorList: colorList,
                  chartRadius: MediaQuery.of(context).size.width / 3.2,
                  ringStrokeWidth: 32,
                  legendOptions: LegendOptions(
                    showLegends: false,
                  ),
                  chartValuesOptions: ChartValuesOptions(
                    showChartValues: true,
                    showChartValuesOutside:
                        true, // Move chart values outside the ring
                    showChartValuesInPercentage:
                        false, // Shows actual values instead of percentage
                    decimalPlaces: 1, // Limit decimal places for clarity
                    chartValueBackgroundColor: Colors
                        .grey.shade200, // Transparent background for the values
                    chartValueStyle: TextStyle(
                      color: Colors.black, // Make text color stand out
                      fontSize: 14, // Slightly smaller font for better fit
                      fontWeight: FontWeight.bold, // Keep bold for visibility
                    ),
                  ),
                ),
              ),
              SizedBox(width: 20),
              // Category legend and values
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        width: 8.0,
                        height: 20.0,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: null,
                   
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sent',
                            style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                          SizedBox(width: 8),
                      Text(
                            '\$$roundedTotalSent', // Dynamic sent amount (rounded)
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                        ],
                      ),
              
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        width: 8.0,
                        height: 20.0,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: null,
                   
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Received',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                      SizedBox(width: 8),
                      Text(
                            '\$$roundedTotalReceived', // Dynamic received amount (rounded)
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to parse date safely
  DateTime _parseDate(dynamic date) {
    if (date is String) {
      return DateTime.parse(date);
    } else if (date is DateTime) {
      return date;
    } else {
      throw FormatException('Invalid date format');
    }
  }
}
