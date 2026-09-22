import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../state/budget_provider.dart';
import '../../constants/app_colors.dart';
import '../widgets/section_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BudgetProvider>();
    final fmt = (double usd) => Currencies.format(usd, p.currency);
    final r = p.exchangeRate;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── PIE CHART ───────────────────────────────────────────────────────
        SectionCard(
          title: 'SPENDING PIE CHART',
          child: SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: _pieSlices(p, r),
                centerSpaceRadius: 0,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(enabled: true),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Pie legend
        SectionCard(
          title: 'CATEGORY BREAKDOWN',
          child: Column(
            children: _buildLegend(p, fmt),
          ),
        ),
        const SizedBox(height: 12),

        // ── LINE CHART ──────────────────────────────────────────────────────
        SectionCard(
          title: 'MONTHLY SPENDING TREND',
          subtitle: 'Last 6 months • updates with currency',
          child: SizedBox(
            height: 200,
            child: _LineChartWidget(p: p, r: r),
          ),
        ),
        const SizedBox(height: 12),

        // ── BAR CHART ───────────────────────────────────────────────────────
        SectionCard(
          title: 'EXPECTED vs ACTUAL',
          child: SizedBox(
            height: 200,
            child: _BarChartWidget(p: p, r: r),
          ),
        ),
        const SizedBox(height: 12),

        // ── TOP CATEGORIES ──────────────────────────────────────────────────
        SectionCard(
          title: 'TOP SPENDING CATEGORIES',
          child: Column(children: _buildTopList(p, fmt)),
        ),
      ],
    );
  }

  List<PieChartSectionData> _pieSlices(BudgetProvider p, double r) {
    final top = p.topSpendingCategories.take(6).toList();
    final total = top.fold<double>(0, (s, e) => s + (e['amount'] as double));
    if (total == 0) {
      return [PieChartSectionData(color: AppColors.divider, value: 1, title: 'No data', radius: 100)];
    }
    return List.generate(top.length, (i) {
      final pct = (top[i]['amount'] as double) / total * 100;
      return PieChartSectionData(
        color: AppColors.chartPalette[i % AppColors.chartPalette.length],
        value: (top[i]['amount'] as double) * r,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 100,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
      );
    });
  }

  List<Widget> _buildLegend(BudgetProvider p, String Function(double) fmt) {
    final top = p.topSpendingCategories.take(6).toList();
    return List.generate(top.length, (i) {
      final item = top[i];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(
              color: AppColors.chartPalette[i % AppColors.chartPalette.length],
              borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Expanded(child: Text(item['name'] as String,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          Text(fmt(item['amount'] as double),
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      );
    });
  }

  List<Widget> _buildTopList(BudgetProvider p, String Function(double) fmt) {
    final items = p.topSpendingCategories;
    final total = items.fold<double>(0, (s, e) => s + (e['amount'] as double));
    if (total == 0) return [const Text('No spending recorded this month.', style: TextStyle(color: AppColors.textMuted))];
    return items.take(8).map((item) {
      final pct = (item['amount'] as double) / total;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(item['name'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text('${fmt(item['amount'] as double)}  ${(pct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
            value: pct, minHeight: 4,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
          )),
        ]),
      );
    }).toList();
  }
}

// ── Line Chart ──────────────────────────────────────────────────────────────
class _LineChartWidget extends StatelessWidget {
  const _LineChartWidget({required this.p, required this.r});
  final BudgetProvider p;
  final double r;

  @override
  Widget build(BuildContext context) {
    final trend = p.sixMonthTrend;
    final monthLabels = trend.map((m) => DateFormat('MMM').format(m['month'] as DateTime)).toList();

    final expSpots = List.generate(trend.length, (i) =>
        FlSpot(i.toDouble(), ((trend[i]['expenses'] as double) * r)));
    final savSpots = List.generate(trend.length, (i) =>
        FlSpot(i.toDouble(), ((trend[i]['savings'] as double) * r)));

    return LineChart(LineChartData(
      backgroundColor: Colors.transparent,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 0.5),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 22,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= monthLabels.length) return const SizedBox();
            return Text(monthLabels[i], style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
          },
        )),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: expSpots, isCurved: true, color: AppColors.teal,
          barWidth: 2.5, dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: AppColors.teal.withOpacity(0.12)),
        ),
        LineChartBarData(
          spots: savSpots, isCurved: true, color: AppColors.pink,
          barWidth: 2.5, dotData: FlDotData(show: true),
        ),
      ],
    ));
  }
}

// ── Bar Chart ───────────────────────────────────────────────────────────────
class _BarChartWidget extends StatelessWidget {
  const _BarChartWidget({required this.p, required this.r});
  final BudgetProvider p;
  final double r;

  @override
  Widget build(BuildContext context) {
    final labels = ['Income', 'Expenses', 'Debt', 'Savings'];
    final expectedUSD = [p.totalIncomeExpectedUSD, p.totalExpenseExpectedUSD + p.totalBillExpectedUSD, p.totalDebtExpectedUSD, p.totalSavingsExpectedUSD];
    final actualUSD   = [p.totalIncomeActualUSD,   p.totalExpenseActualUSD + p.totalBillActualUSD,   p.totalDebtActualUSD,   p.totalSavingsActualUSD];

    return BarChart(BarChartData(
      backgroundColor: Colors.transparent,
      alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 0.5),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 22,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox();
            return Text(labels[i], style: const TextStyle(color: AppColors.textMuted, fontSize: 9));
          },
        )),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(labels.length, (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: expectedUSD[i] * r, color: AppColors.teal, width: 10, borderRadius: BorderRadius.circular(4)),
          BarChartRodData(toY: actualUSD[i]   * r, color: AppColors.lavender, width: 10, borderRadius: BorderRadius.circular(4)),
        ],
      )),
    ));
  }
}
