import { useEffect, useState } from "react";
import { Minus, Plus } from "lucide-react";

import { getVenueServices } from "@/features/venue/api/venueApi";
import type { ServiceItemResponse } from "@/features/venue/types/venue.types";
import { getApiErrorMessage } from "@/shared/utils/apiError";

export type SelectedServices = Record<number, number>;

interface ServiceSelectorProps {
  venueId: number;
  selectedServices: SelectedServices;
  onChange: (services: SelectedServices) => void;
  onServicesLoaded?: (services: ServiceItemResponse[]) => void;
}

const toNumber = (value: string | number | null | undefined) => Number(value ?? 0);

const formatCurrency = (amount: string | number | null | undefined) =>
  `${toNumber(amount).toLocaleString("vi-VN")} VND`;

export function ServiceSelector({
  venueId,
  selectedServices,
  onChange,
  onServicesLoaded,
}: ServiceSelectorProps) {
  const [services, setServices] = useState<ServiceItemResponse[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    const fetchServices = async () => {
      if (!venueId) return;
      setLoading(true);
      setError(null);

      try {
        const data = await getVenueServices(venueId);
        if (cancelled) return;
        setServices(data);
        onServicesLoaded?.(data);
      } catch (err) {
        if (cancelled) return;
        setServices([]);
        onServicesLoaded?.([]);
        setError(getApiErrorMessage(err, "Không thể tải dịch vụ."));
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    };

    fetchServices();

    return () => {
      cancelled = true;
    };
  }, [venueId, onServicesLoaded]);

  const updateQuantity = (serviceId: number, nextQuantity: number) => {
    const safeQuantity = Math.max(0, nextQuantity);
    const next = { ...selectedServices };
    if (safeQuantity === 0) {
      delete next[serviceId];
    } else {
      next[serviceId] = safeQuantity;
    }
    onChange(next);
  };

  if (loading) {
    return (
      <div className="rounded-2xl border border-dashed border-gray-200 bg-white p-4 text-sm text-gray-500 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-400">
        Đang tải dịch vụ...
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-700 dark:border-amber-400/40 dark:bg-amber-500/10 dark:text-amber-200">
        {error}
      </div>
    );
  }

  if (!services.length) {
    return null;
  }

  return (
    <section className="rounded-2xl border border-gray-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-800">
      <div className="mb-3 flex items-center justify-between gap-3">
        <h2 className="text-sm font-semibold text-gray-900 dark:text-slate-100">
          Dịch vụ kèm theo
        </h2>
      </div>
      <div className="space-y-3">
        {services.map((service) => {
          const quantity = selectedServices[service.id] ?? 0;
          return (
            <div
              key={service.id}
              className="flex items-center justify-between gap-3 border-t border-gray-100 pt-3 first:border-t-0 first:pt-0 dark:border-slate-700"
            >
              <div className="min-w-0">
                <p className="truncate text-sm font-semibold text-gray-900 dark:text-slate-100">
                  {service.name}
                </p>
                <p className="text-xs text-gray-500 dark:text-slate-400">
                  {formatCurrency(service.price)} / {service.unit}
                </p>
              </div>
              <div className="flex h-9 shrink-0 items-center overflow-hidden rounded-lg border border-gray-200 dark:border-slate-600">
                <button
                  type="button"
                  className="flex h-9 w-9 items-center justify-center text-gray-600 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-40 dark:text-slate-200 dark:hover:bg-slate-700"
                  onClick={() => updateQuantity(service.id, quantity - 1)}
                  disabled={quantity === 0}
                  aria-label={`Giảm ${service.name}`}
                >
                  <Minus size={15} />
                </button>
                <span className="flex h-9 w-10 items-center justify-center text-sm font-semibold text-gray-900 dark:text-slate-100">
                  {quantity}
                </span>
                <button
                  type="button"
                  className="flex h-9 w-9 items-center justify-center text-gray-600 hover:bg-gray-50 dark:text-slate-200 dark:hover:bg-slate-700"
                  onClick={() => updateQuantity(service.id, quantity + 1)}
                  aria-label={`Tăng ${service.name}`}
                >
                  <Plus size={15} />
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
