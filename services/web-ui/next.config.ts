import type { NextConfig } from "next";
import { env } from "process";

const { i18n } = require('./next-i18next.config')

const nextConfig: NextConfig = {
  ...(env.REPLIT_DOMAINS ? { allowedDevOrigins: [env.REPLIT_DOMAINS.split(",")[0]] } : {}),
  i18n,
  reactStrictMode: true,
  // Enable standalone output for Docker
  output: 'standalone',
  // ESLint configuration for build
  eslint: {
    // Warning: This allows production builds to successfully complete even if
    // your project has ESLint errors.
    ignoreDuringBuilds: false,
  },
};

module.exports = nextConfig;
