import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/sms_parser_service.dart';
import '../../state/budget_provider.dart';
import '../../constants/app_colors.dart';

class SmsSuggestionsScreen extends StatefulWidget {
  const SmsSuggestionsScreen({super.key});

  @override
  State<SmsSuggestionsScreen> createState() => _SmsSuggestionsScreenState();
}

class _SmsSuggestionsScreenState extends State<SmsSuggestionsScreen> {
  final Telephony telephony = Telephony.instance;
  List<SmsTransaction> _suggestions = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scanSms();
  }

  Future<void> _scanSms() async {
    setState(() { _loading = true; _error = null; });
    
    // Request permission
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      setState(() {
        _loading = false;
        _error = 'SMS permission denied. Cannot scan for transactions.';
      });
      return;
    }

    try {
      final messages = await telephony.getInboxSms(
        columns: [SmsColumn.ID, SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      // Load already processed SMS IDs from storage
      final box = Hive.box('settings');
      final processed = List<String>.from(box.get('processed_sms', defaultValue: <String>[]) ?? <String>[]);

      final List<SmsTransaction> found = [];
      // Scan last 100 messages for speed
      for (var msg in messages.take(100)) {
        if (msg.body == null || msg.address == null) continue;
        
        final smsId = msg.id?.toString() ?? msg.date.toString();
        // Skip this SMS if we have already saved it or dismissed it!
        if (processed.contains(smsId)) continue; 

        final date = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);
        
        final tx = SmsParserService.parse(msg.body!, msg.address!, date, smsId);
        if (tx != null) {
          found.add(tx);
        }
      }

      setState(() {
        _suggestions = found;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error reading SMS: $e';
      });
    }
  }

  void _markAsProcessed(String smsId) {
    final box = Hive.box('settings');
    final processed = List<String>.from(box.get('processed_sms', defaultValue: <String>[]) ?? <String>[]);
    processed.add(smsId);
    box.put('processed_sms', processed);
  }

  void _addTransaction(SmsTransaction tx) {
    // 1. Mark as permanently processed so it never shows up here again
    _markAsProcessed(tx.smsId);

    // 2. Determine category based on merchant or fallback
    String category = 'Miscellaneous'; // fallback
    if (tx.merchant.toLowerCase().contains('zomato') || tx.merchant.toLowerCase().contains('swiggy')) category = 'Food';
    if (tx.merchant.toLowerCase().contains('uber') || tx.merchant.toLowerCase().contains('ola')) category = 'Transportation';
    if (tx.merchant.toLowerCase().contains('amazon')) category = 'Household';

    context.read<BudgetProvider>().addTransaction(
      type: tx.isDebit ? 'expense' : 'income',
      category: category,
      amountUSD: tx.amount, // Note: For Indian users this is INR, they should set currency to INR in settings
      dateTime: tx.dateTime,
      description: tx.merchant,
    );

    setState(() {
      _suggestions.remove(tx);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction added!'), backgroundColor: AppColors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Auto-Read'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _scanSms),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.peach), textAlign: TextAlign.center))
              : _suggestions.isEmpty
                  ? const Center(child: Text('No new bank transactions found.', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final tx = _suggestions[index];
                        final color = tx.isDebit ? AppColors.peach : AppColors.teal;
                        
                        return Card(
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(tx.merchant, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text('${tx.isDebit ? '-' : '+'}${tx.amount.toStringAsFixed(2)}', 
                                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(tx.rawBody, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        _markAsProcessed(tx.smsId);
                                        setState(() => _suggestions.removeAt(index));
                                      },
                                      child: const Text('Dismiss', style: TextStyle(color: AppColors.textMuted)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _addTransaction(tx),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
                                      child: const Text('Add Transaction', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
