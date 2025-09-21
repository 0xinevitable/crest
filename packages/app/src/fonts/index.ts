import { Instrument_Sans } from 'next/font/google';
import localFont from 'next/font/local';

export const OpticianSans = localFont({
  src: './Optician-Sans.otf',
  display: 'block',
  fallback: ['Optician Sans', 'Inter', 'sans-serif'],
});

export const InstrumentSans = Instrument_Sans({
  subsets: ['latin'],
  weight: ['400', '500', '600', '700'],
});
