import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/account_provider.dart';
import '../theme/app_colors.dart';
import '../utils/insight_engine.dart';
import 'package:collection/collection.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseProvider);
    final accounts = ref.watch(accountProvider);

    final categoryTotals = groupBy(expenses, (dynamic e) => e.category)
        .map((cat, exps) => MapEntry(cat, exps.fold(0.0, (sum, e) => sum + e.amount)));

    final insights = InsightEngine.generateInsights(expenses, accounts);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Spending by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: categoryTotals.isEmpty 
                ? const Center(child: Text('No data yet'))
                : PieChart(
                  PieChartData(
                    sections: categoryTotals.entries.map((entry) {
                      return PieChartSectionData(
                        color: _getCategoryColor(entry.key),
                        value: entry.value,
                        title: '${entry.key}\n${entry.value.toStringAsFixed(0)}',
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
            ),
            const SizedBox(height: 40),
            const Text('Spending per Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: accounts.isEmpty 
                ? const Center(child: Text('No accounts yet'))
                : BarChart(
                  BarChartData(
                    barGroups: accounts.asMap().entries.map((entry) {
                      final accountExpenses = expenses.where((e) => e.accountId == entry.value.id);
                      final total = accountExpenses.fold(0.0, (sum, e) => sum + e.amount);
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: total,
                            color: AppColors.primary,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < accounts.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  accounts[value.toInt()].name.substring(0, 3),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
            ),
            const SizedBox(height: 40),
            const Text('Smart Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...insights.map((insight) => _buildInsightCard(context, insight)),
            const SizedBox(height: 32),
            const Text('Monthly Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSummaryStats(expenses),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(List<dynamic> expenses) {
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    return Row(
      children: [
        _buildStatBox('Total Spent', '₹${total.toStringAsFixed(0)}', AppColors.error),
        const SizedBox(width: 16),
        _buildStatBox('Transactions', '${expenses.length}', AppColors.info),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Colors.orange;
      case 'travel': return Colors.blue;
      case 'shopping': return Colors.pink;
      case 'bills': return Colors.purple;
      case 'health': return Colors.green;
      case 'entertainment': return Colors.red;
      default: return Colors.grey;
    }
  }
}
