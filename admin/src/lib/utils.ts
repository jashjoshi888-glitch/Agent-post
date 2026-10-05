// Small helper used by the UI components: joins class names together and
// lets later classes override earlier ones (the standard "cn" utility from
// shadcn/ui).
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
