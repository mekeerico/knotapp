class CurrencyInfo {
  final String code;
  final String symbol;
  final double rate;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.rate,
  });
}

class CurrencyService {
  static const CurrencyInfo defaultCurrency = CurrencyInfo(
    code: 'USD',
    symbol: '\$',
    rate: 1.0,
  );

  static const List<String> africanCountries = [
    'nigeria',
    'ghana',
    'kenya',
    'south africa',
    'uganda',
    'tanzania',
    'rwanda',
    'ethiopia',
    'cameroon',
    'senegal',
    'egypt',
  ];

  static const Map<String, CurrencyInfo> currencyMap = {
    'united states': CurrencyInfo(code: 'USD', symbol: '\$', rate: 1.0),
    'united states of america': CurrencyInfo(code: 'USD', symbol: '\$', rate: 1.0),
    'nigeria': CurrencyInfo(code: 'NGN', symbol: '₦', rate: 1600.0),
    'united kingdom': CurrencyInfo(code: 'GBP', symbol: '£', rate: 0.79),
    'canada': CurrencyInfo(code: 'CAD', symbol: 'C\$', rate: 1.36),
    'australia': CurrencyInfo(code: 'AUD', symbol: 'A\$', rate: 1.52),
    'ghana': CurrencyInfo(code: 'GHS', symbol: 'GH₵', rate: 15.2),
    'kenya': CurrencyInfo(code: 'KES', symbol: 'KSh', rate: 131.5),
    'south africa': CurrencyInfo(code: 'ZAR', symbol: 'R', rate: 18.8),
    'germany': CurrencyInfo(code: 'EUR', symbol: '€', rate: 0.92),
    'france': CurrencyInfo(code: 'EUR', symbol: '€', rate: 0.92),
    'italy': CurrencyInfo(code: 'EUR', symbol: '€', rate: 0.92),
    'spain': CurrencyInfo(code: 'EUR', symbol: '€', rate: 0.92),
    'ireland': CurrencyInfo(code: 'EUR', symbol: '€', rate: 0.92),
    'netherlands': CurrencyInfo(code: 'EUR', symbol: '€', rate: 0.92),
    'india': CurrencyInfo(code: 'INR', symbol: '₹', rate: 83.45),
    'united arab emirates': CurrencyInfo(code: 'AED', symbol: 'AED', rate: 3.67),
  };

  static bool isAfrica(String? country) {
    if (country == null || country.isEmpty) return false;
    final lower = country.trim().toLowerCase();
    return africanCountries.any((c) => lower.contains(c));
  }

  static CurrencyInfo getCurrencyForCountry(String? country) {
    if (country == null || country.isEmpty) return defaultCurrency;
    final lower = country.trim().toLowerCase();
    for (final entry in currencyMap.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }
    return defaultCurrency;
  }

  /// Calculates the tier price in USD based on global vs African rates
  static double getTierPriceUSD(String tier, String? country) {
    final t = tier.toLowerCase();
    final isAfr = isAfrica(country);

    if (t.contains('premium')) {
      // Premium: $14.99 Global / $12.00 Africa (yielding exactly ₦19,200 at 1600 rate)
      return isAfr ? 12.00 : 14.99;
    } else if (t.contains('elite')) {
      // Elite: $39.99 Global / $25.00 Africa (yielding exactly ₦40,000 at 1600 rate)
      return isAfr ? 25.00 : 39.99;
    } else if (t.contains('executive')) {
      // Executive: $199.00
      return 199.00;
    }
    return 14.99;
  }

  /// Formats tier price in user's local country currency with USD settlement note
  static String formatTierPrice(String tier, String? country) {
    final usdAmount = getTierPriceUSD(tier, country);
    final currency = getCurrencyForCountry(country);

    if (currency.code == 'USD') {
      return '\$${usdAmount.toStringAsFixed(2)} / mo';
    }

    final localAmount = (usdAmount * currency.rate).round();
    // Format nicely e.g. ₦19,200 or ₦44,800 or £11.99
    final formattedLocal = localAmount >= 1000
        ? _formatThousands(localAmount)
        : (usdAmount * currency.rate).toStringAsFixed(2);

    return '${currency.symbol}$formattedLocal / mo';
  }

  /// Formats secondary settlement subtitle (e.g. "~ $14.99 USD billed via Play Store")
  static String getSettlementSubtitle(String tier, String? country) {
    final usdAmount = getTierPriceUSD(tier, country);
    final currency = getCurrencyForCountry(country);
    if (currency.code == 'USD') {
      return 'Billed in USD via Google Play';
    }
    return 'Billed as \$${usdAmount.toStringAsFixed(2)} USD in Google Play';
  }

  static String _formatThousands(int num) {
    return num.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
