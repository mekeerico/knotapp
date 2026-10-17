import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    const backendUrl = process.env.INTERNAL_BACKEND_URL || "http://backend-core:8080";
    return [
      {
        source: "/api-backend/:path*",
        destination: `${backendUrl}/:path*`,
      },
      {
        source: "/uploads/:path*",
        destination: `${backendUrl}/uploads/:path*`,
      },
    ];
  },
};

export default nextConfig;
