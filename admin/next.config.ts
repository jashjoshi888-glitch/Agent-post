import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  // The repository contains several package.json files (root tooling + admin);
  // tell Next.js exactly where this app lives so builds are reproducible.
  outputFileTracingRoot: path.join(__dirname),
};

export default nextConfig;
