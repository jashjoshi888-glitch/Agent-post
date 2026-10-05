// Shared "not built yet" card for dashboard sections that arrive in later
// phases. (Developer-facing — these pages get real content before launch.)
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export function PlaceholderPage({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold tracking-tight">{title}</h1>
      <Card>
        <CardHeader>
          <CardTitle>Under development</CardTitle>
          <CardDescription>{description}</CardDescription>
        </CardHeader>
        <CardContent>
          <p className="rounded-md border border-dashed border-slate-300 bg-slate-50 p-4 text-sm text-slate-600">
            This section will be filled in during a later development phase.
            Nothing to configure here yet.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
