export interface CurrencyInfo {
  code: string;
  symbol: string;
  rate: number;
}

export const CURRENCY_MAP: Record<string, CurrencyInfo> = {
  'United States of America': { code: 'USD', symbol: '$', rate: 1 },
  Nigeria: { code: 'NGN', symbol: '₦', rate: 1600 },
  'United Kingdom': { code: 'GBP', symbol: '£', rate: 0.79 },
  Canada: { code: 'CAD', symbol: 'C$', rate: 1.36 },
  India: { code: 'INR', symbol: '₹', rate: 83.45 },
  Ghana: { code: 'GHS', symbol: 'GH₵', rate: 15.2 },
  Kenya: { code: 'KES', symbol: 'KSh', rate: 131.5 },
  'South Africa': { code: 'ZAR', symbol: 'R', rate: 18.8 },
  Pakistan: { code: 'PKR', symbol: 'Rs', rate: 278.5 },
  Mexico: { code: 'MXN', symbol: '$', rate: 16.7 },
  Brazil: { code: 'BRL', symbol: 'R$', rate: 5.15 },
  'United Arab Emirates': { code: 'AED', symbol: 'AED', rate: 3.67 },
  Australia: { code: 'AUD', symbol: 'A$', rate: 1.52 },
  Germany: { code: 'EUR', symbol: '€', rate: 0.92 },
  France: { code: 'EUR', symbol: '€', rate: 0.92 },
};

export const DEFAULT_CURRENCY: CurrencyInfo = { code: 'USD', symbol: '$', rate: 1 };
export const PAYSTACK_SUPPORTED_CURRENCIES = ['NGN', 'USD', 'GHS', 'KES', 'ZAR'];

export const AFRICAN_COUNTRIES = ['Nigeria', 'Ghana', 'Kenya', 'South Africa'];

export const TIER_PRICES = {
  Essential: { global: 0, africa: 0 },
  Premium: { global: 14.99, africa: 12.00 },
  Elite: { global: 39.99, africa: 25.00 },
  Executive: { global: 199.00, africa: 199.00 },
};

export const getTierPriceUSD = (tier: 'Essential' | 'Premium' | 'Elite' | 'Executive', country: string): number => {
  if (tier === 'Essential') return 0;
  const isAfrica = AFRICAN_COUNTRIES.includes(country);
  return isAfrica ? TIER_PRICES[tier].africa : TIER_PRICES[tier].global;
};

export const formatTierPrice = (tier: 'Essential' | 'Premium' | 'Elite' | 'Executive', country: string = 'United States of America'): string => {
  if (tier === 'Essential') return 'Free';
  const isAfrica = AFRICAN_COUNTRIES.includes(country);
  const usdAmount = getTierPriceUSD(tier, country);
  
  if (isAfrica) {
    const info = CURRENCY_MAP[country] || DEFAULT_CURRENCY;
    const localValue = usdAmount * info.rate;
    return `${info.symbol}${localValue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  } else {
    // Force USD for non-African countries
    return `$${usdAmount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  }
};


export const formatLocalPrice = (usdAmount: number, country: string = 'United States of America'): string => {
  const info = CURRENCY_MAP[country] || DEFAULT_CURRENCY;
  const localValue = usdAmount * info.rate;
  return `${info.symbol}${localValue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
};

export const getCurrencyForCountry = (country: string): CurrencyInfo => {
  return CURRENCY_MAP[country] || DEFAULT_CURRENCY;
};

export const getPaystackCurrency = (country: string): CurrencyInfo => {
  const local = CURRENCY_MAP[country] || DEFAULT_CURRENCY;
  if (PAYSTACK_SUPPORTED_CURRENCIES.includes(local.code)) return local;
  return DEFAULT_CURRENCY;
};
