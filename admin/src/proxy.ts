// Next.js 16 request interceptor (formerly "middleware.ts").
// Only keeps the Supabase login session fresh — access control is enforced
// in the dashboard layout (src/app/(dashboard)/layout.tsx).
import { type NextRequest } from "next/server";

import { updateSession } from "@/lib/supabase/proxy";

export default async function proxy(request: NextRequest) {
  return await updateSession(request);
}

export const config = {
  // Run on everything except static files and images.
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
