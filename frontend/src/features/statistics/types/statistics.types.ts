import type { LucideIcon } from "lucide-react";

export interface PitchPerformanceDto {
  pitchId: number;
  pitchName: string;
  bookingCount: number;
  revenue: number;
}

export interface DashboardStatsResponse {
  totalRevenue: number;
  totalBookings: number;
  canceledBookings: number;
  uniqueCustomers: number;
  occupancyRate: number;
  pitchPerformances: PitchPerformanceDto[];
}

export interface RecentOrderDto {
  id: string;
  customerName: string;
  fieldName: string;
  bookingTime: string;
  price: number;
  status: string;
}

export interface DashboardStatCard {
  title: string;
  value: string;
  icon: LucideIcon;
  trend: {
    value: string;
    direction: "up" | "down";
  };
}
