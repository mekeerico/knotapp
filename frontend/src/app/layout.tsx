import type { Metadata } from "next";
import { Inter, Lora } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-sans",
});

const lora = Lora({
  subsets: ["latin"],
  variable: "--font-serif",
});

export const metadata: Metadata = {
  title: "KNOT | Where True Relationship Leads to Vow",
  description: "KNOT is a premium, AI-powered relationship intelligence platform for verified serious singles seeking marriage and long-term commitment. No games. No fakes. Just real connections.",
  icons: {
    icon: [
      { url: "/knot-icon.png?v=4", sizes: "192x192", type: "image/png" },
      { url: "/favicon.png?v=4", sizes: "64x64", type: "image/png" },
      { url: "/favicon.ico?v=4", sizes: "32x32", type: "image/x-icon" },
    ],
    shortcut: ["/knot-icon.png?v=4"],
    apple: [
      { url: "/knot-icon.png?v=4", sizes: "192x192", type: "image/png" },
    ],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark scroll-smooth">
      <head>
        <link rel="icon" type="image/png" sizes="192x192" href="/knot-icon.png?v=4" />
        <link rel="icon" type="image/png" sizes="64x64" href="/favicon.png?v=4" />
        <link rel="shortcut icon" href="/favicon.ico?v=4" />
        <link rel="apple-touch-icon" href="/knot-icon.png?v=4" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
      </head>
      <body
        className={`${inter.variable} ${lora.variable} antialiased bg-[#0A0E14] text-[#F5F5F1] min-h-screen relative overflow-x-hidden`}
      >
        {/* Soft background ambient gradient */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full max-w-7xl h-[600px] brand-bg-glow pointer-events-none -z-10" />
        {children}
      </body>
    </html>
  );
}
