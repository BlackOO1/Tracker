// ── SMS Parser Service ──────────────────────────────────────────────────────
// Parses bank/UPI SMS messages common in India and extracts transaction info.

class SmsTransaction {
  final String smsId;
  final double amount;
  final String merchant;
  final bool isDebit; // true = expense, false = income
  final DateTime dateTime;
  final String rawBody;

  SmsTransaction({
    required this.smsId,
    required this.amount,
    required this.merchant,
    required this.isDebit,
    required this.dateTime,
    required this.rawBody,
  });
}

class SmsParserService {
  // Matches: "Rs.500", "INR 500", "Rs 500.00", "USD 100"
  static final _amountRx = RegExp(
    r'(?:Rs\.?|INR|USD|EUR|GBP)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  // Debit keywords
  static final _debitRx = RegExp(
    r'\b(debited|deducted|spent|paid|payment of|withdrawn|purchase|dr\.?)\b',
    caseSensitive: false,
  );

  // Credit keywords
  static final _creditRx = RegExp(
    r'\b(credited|received|credit of|deposited|added|cr\.?)\b',
    caseSensitive: false,
  );

  // Merchant/UPI extraction patterns
  static final _merchantRx = RegExp(
    r'(?:to|at|for|towards|via|merchant[:\s]+|VPA[:\s]+)\s*([A-Za-z0-9@.\-_ ]{3,30})',
    caseSensitive: false,
  );

  // Bank sender filter (only parse bank messages)
  static final _bankSenderRx = RegExp(
    r'^(SBI|HDFC|ICICI|AXIS|BOI|PNB|KOTAKBK|YESBANK|INDUS|PAYTM|PHONEPE|GPAY|AMAZON|BHARATPE|AUBANK)',
    caseSensitive: false,
  );

  static bool isBankSms(String sender) =>
      _bankSenderRx.hasMatch(sender.replaceAll('-', '').trim().toUpperCase());

  static SmsTransaction? parse(String body, String sender, DateTime date, String smsId) {
    if (!isBankSms(sender)) return null;

    final amtMatch = _amountRx.firstMatch(body);
    if (amtMatch == null) return null;

    final amtStr = amtMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(amtStr);
    if (amount == null || amount <= 0) return null;

    final isDebit = _debitRx.hasMatch(body) || !_creditRx.hasMatch(body);

    String merchant = 'Unknown';
    final mMatch = _merchantRx.firstMatch(body);
    if (mMatch != null) {
      merchant = mMatch.group(1)!.trim();
      // Trim trailing garbage
      if (merchant.length > 25) merchant = merchant.substring(0, 25).trim();
    }

    return SmsTransaction(
      smsId: smsId,
      amount: amount,
      merchant: merchant,
      isDebit: isDebit,
      dateTime: date,
      rawBody: body,
    );
  }
}
