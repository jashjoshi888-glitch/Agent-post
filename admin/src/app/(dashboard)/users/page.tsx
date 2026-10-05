// Users page — WORKING in Phase 1.
//
// Lists every agent with their basic profile info (read-only). This works
// without any special keys: the admin's own login is allowed by the database
// security rules to read all profile rows (and nobody else is).
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { createClient } from "@/lib/supabase/server";

type ProfileRow = {
  id: string;
  full_name: string | null;
  agency_name: string | null;
  designation: string | null;
  mobile_whatsapp: string | null;
  licence_number: string | null;
  onboarding_completed: boolean;
  created_at: string;
};

export default async function UsersPage() {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("profiles")
    .select(
      "id, full_name, agency_name, designation, mobile_whatsapp, licence_number, onboarding_completed, created_at"
    )
    .order("created_at", { ascending: false });

  const profiles = (data ?? []) as ProfileRow[];

  return (
    <div>
      <h1 className="mb-1 text-2xl font-bold tracking-tight">Users</h1>
      <p className="mb-6 text-sm text-slate-600">
        All registered agents. Read-only for now.
      </p>

      <Card>
        <CardHeader>
          <CardTitle>Agents ({profiles.length})</CardTitle>
          <CardDescription>
            New agents appear here automatically after they sign up.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {error ? (
            <p className="rounded-md bg-red-50 p-4 text-sm text-red-700">
              Could not load users: {error.message}
            </p>
          ) : profiles.length === 0 ? (
            <p className="rounded-md border border-dashed border-slate-300 bg-slate-50 p-4 text-sm text-slate-600">
              No agents yet. As soon as somebody signs up in the app, they will
              show up here.
            </p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Agency</TableHead>
                  <TableHead>Designation</TableHead>
                  <TableHead>Mobile</TableHead>
                  <TableHead>Licence no.</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Joined</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {profiles.map((profile) => (
                  <TableRow key={profile.id}>
                    <TableCell className="font-medium">
                      {profile.full_name ?? "—"}
                    </TableCell>
                    <TableCell>{profile.agency_name ?? "—"}</TableCell>
                    <TableCell>{profile.designation ?? "—"}</TableCell>
                    <TableCell>{profile.mobile_whatsapp ?? "—"}</TableCell>
                    <TableCell>{profile.licence_number ?? "—"}</TableCell>
                    <TableCell>
                      {profile.onboarding_completed ? (
                        <Badge variant="success">Active</Badge>
                      ) : (
                        <Badge variant="secondary">Setup pending</Badge>
                      )}
                    </TableCell>
                    <TableCell className="whitespace-nowrap text-slate-600">
                      {new Date(profile.created_at).toLocaleDateString("en-IN", {
                        day: "numeric",
                        month: "short",
                        year: "numeric",
                      })}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
