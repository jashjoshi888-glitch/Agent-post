// Dashboard layout — THE access gate of the admin dashboard.
//
// On every page it checks, on the server:
//   1. somebody is signed in, and
//   2. that person is listed in the `admin_users` table.
// Anyone else is sent back to the login page, no matter what the browser does.
import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";
import { SidebarNav } from "@/components/sidebar-nav";
import { SignOutButton } from "@/components/sign-out-button";
import { Separator } from "@/components/ui/separator";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  // "Am I an admin?" — the database allows each user to read only their own
  // membership row, so this works without exposing the full admin list.
  const { data: adminRow } = await supabase
    .from("admin_users")
    .select("user_id")
    .eq("user_id", user.id)
    .maybeSingle();

  if (!adminRow) {
    redirect("/login?error=not_admin");
  }

  return (
    <div className="flex min-h-screen bg-slate-100">
      <aside className="fixed inset-y-0 left-0 z-10 flex w-64 flex-col border-r border-slate-200 bg-white p-4">
        <div className="mb-6 flex items-center gap-3 px-2">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-slate-900 text-sm font-bold text-white">
            A
          </div>
          <div>
            <p className="text-sm font-semibold leading-tight">AgentPost</p>
            <p className="text-xs text-slate-500">Admin dashboard</p>
          </div>
        </div>

        <SidebarNav />

        <div className="mt-auto space-y-3">
          <Separator />
          <p className="truncate px-2 text-xs text-slate-500">{user.email}</p>
          <SignOutButton />
        </div>
      </aside>

      <main className="ml-64 flex-1 p-8">{children}</main>
    </div>
  );
}
