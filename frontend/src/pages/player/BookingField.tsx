import { useEffect, useMemo, useState } from "react";
import { format } from "date-fns";
import { ArrowLeft } from "lucide-react";
import { useNavigate, useParams } from "react-router-dom";

import {
  DateSelector,
  SelectedSlotsBar,
  ServiceSelector,
  SlotsGrid,
  useAvailableSlots,
  useSlotSelection,
} from "@/features/booking";
import type {
  ServiceItemResponse,
  SlotStatusResponse,
} from "@/features/venue/types/venue.types";
import { createBooking } from "@/features/booking/api/bookingApi";
import type { SlotDisplayItem } from "@/features/booking/components/player/SlotsGrid";
import { getApiErrorMessage, logApiError } from "@/shared/utils/apiError";
import { BookingConfirmModal } from "@/features/booking/components/player/BookingConfirmModal";

const normalizeTime = (value: string) => value.slice(0, 5);

/** Map a raw SlotStatusResponse → SlotDisplayItem with pricing metadata attached */
const toSlotDisplayItem = (
  slot: SlotStatusResponse,
  status: SlotDisplayItem["status"],
): SlotDisplayItem => ({
  slot: {
    startTime: normalizeTime(slot.startTime),
    endTime: normalizeTime(slot.endTime),
  },
  status,
  timeSlotId: slot.timeSlotId,
  price: slot.price != null ? Number(slot.price) : null,
});

const sortSlotItems = (a: SlotDisplayItem, b: SlotDisplayItem) =>
  a.slot.startTime.localeCompare(b.slot.startTime);

const toNumber = (value: string | number | null | undefined) => Number(value ?? 0);

export function BookingField() {
  const navigate = useNavigate();
  const { fieldId } = useParams();
  const venueId = Number(fieldId) || 1;

  const [selectedDate, setSelectedDate] = useState(new Date());
  const [selectedPitchId, setSelectedPitchId] = useState<number | null>(null);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [selectedServices, setSelectedServices] = useState<Record<number, number>>({});
  const [availableServices, setAvailableServices] = useState<ServiceItemResponse[]>([]);
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [pendingBooking, setPendingBooking] = useState<{
    pitchId: number;
    bookingDate: string;
    /** Enriched items (carry timeSlotId + price) for the confirm modal */
    slots: SlotDisplayItem[];
    timeSlotIds: number[];
    totalPrice: number;
  } | null>(null);

  const { selectedSlots, toggleSlot, clearSlots } = useSlotSelection({
    resetKey: [selectedDate, selectedPitchId],
  });

  const {
    loading,
    error,
    slots,
    pitch,
    venueAvailability,
    refresh,
    lastUpdated,
  } = useAvailableSlots(venueId, selectedPitchId ?? 0, selectedDate, {
    refreshIntervalMs: 15000,
    autoRefresh,
  });

  useEffect(() => {
    if (!selectedPitchId && venueAvailability?.pitches.length) {
      setSelectedPitchId(venueAvailability.pitches[0].pitchId);
    }
  }, [selectedPitchId, venueAvailability]);

  useEffect(() => {
    setSubmitError(null);
    setSubmitSuccess(null);
  }, [selectedDate, selectedPitchId]);

  const slotItems = useMemo<SlotDisplayItem[]>(() => {
    return slots
      .map((slot) => {
        const startNorm = normalizeTime(slot.startTime);
        const endNorm = normalizeTime(slot.endTime);

        if (slot.status === "PENDING") {
          return toSlotDisplayItem(slot, "pending");
        }

        if (slot.status !== "AVAILABLE") {
          return toSlotDisplayItem(slot, "booked");
        }

        const isSelected = selectedSlots.some(
          (item) => item.startTime === startNorm && item.endTime === endNorm,
        );

        return toSlotDisplayItem(slot, isSelected ? "selected" : "available");
      })
      .sort(sortSlotItems);
  }, [slots, selectedSlots]);

  const selectedSlotDetails = useMemo(() => {
    return selectedSlots
      .map((slot) =>
        slots.find(
          (item) =>
            normalizeTime(item.startTime) === slot.startTime &&
            normalizeTime(item.endTime) === slot.endTime,
        ),
      )
      .filter((slot): slot is SlotStatusResponse => Boolean(slot));
  }, [selectedSlots, slots]);

  const fieldTotal = useMemo(() => {
    return selectedSlotDetails.reduce(
      (total, slot) => total + toNumber(slot.price),
      0,
    );
  }, [selectedSlotDetails]);

  const serviceTotal = useMemo(() => {
    return availableServices.reduce((total, service) => {
      const quantity = selectedServices[service.id] ?? 0;
      return total + quantity * toNumber(service.price);
    }, 0);
  }, [availableServices, selectedServices]);

  const selectedServicePayload = useMemo(() => {
    return Object.entries(selectedServices)
      .map(([serviceId, quantity]) => ({
        serviceId: Number(serviceId),
        quantity,
      }))
      .filter((item) => item.quantity > 0);
  }, [selectedServices]);

  const handleSubmit = () => {
    if (!selectedPitchId) {
      setSubmitError("Vui lòng chọn sân trước khi đặt.");
      return;
    }
    if (!selectedSlots.length) {
      setSubmitError("Vui lòng chọn ít nhất một khung giờ.");
      return;
    }

    // Resolve enriched SlotDisplayItems from the live slotItems grid.
    // This guarantees timeSlotId/price are fresh and that selected slots
    // are still AVAILABLE (not booked by another user since last refresh).
    const enrichedSlots: SlotDisplayItem[] = [];
    const unavailableSlots: string[] = [];

    for (const sel of selectedSlots) {
      const live = slotItems.find(
        (item) =>
          item.slot.startTime === sel.startTime &&
          item.slot.endTime === sel.endTime,
      );

      if (!live) {
        // Slot disappeared from API response entirely — treat as unavailable
        unavailableSlots.push(`${sel.startTime}–${sel.endTime}`);
        continue;
      }

      if (live.status === "booked") {
        unavailableSlots.push(`${sel.startTime}–${sel.endTime}`);
        continue;
      }

      if (live.timeSlotId == null) {
        setSubmitError(
          `Không thể xác định timeSlotId cho khung giờ ${sel.startTime}–${sel.endTime}.`,
        );
        return;
      }

      enrichedSlots.push(live);
    }

    if (unavailableSlots.length > 0) {
      setSubmitError(
        `Khung giờ sau đã được đặt bởi người khác: ${unavailableSlots.join(", ")}. Vui lòng chọn lại.`,
      );
      // Remove stale selections so the grid reflects reality
      clearSlots();
      refresh();
      return;
    }

    const timeSlotIds = enrichedSlots.map((item) => item.timeSlotId as number);
    const totalPrice = enrichedSlots.reduce(
      (sum, item) => sum + (item.price ?? 0),
      0,
    );

    setSubmitError(null);
    setPendingBooking({
      pitchId: selectedPitchId,
      bookingDate: format(selectedDate, "yyyy-MM-dd"),
      slots: enrichedSlots,
      timeSlotIds,
      totalPrice,
    });
    setShowConfirmModal(true);
  };

  const handleConfirmBooking = async () => {
    if (!pendingBooking) return;

    setIsSubmitting(true);
    setSubmitError(null);
    setSubmitSuccess(null);

    try {
      // Each timeSlotId requires a separate POST /player/bookings request.
      // Promise.all sends them in parallel; if any fails the whole batch is
      // treated as failed (partial success is surfaced via error message).
      await Promise.all(
        pendingBooking.timeSlotIds.map((timeSlotId, index) =>
          createBooking({
            pitchId: pendingBooking.pitchId,
            bookingDate: pendingBooking.bookingDate,
            timeSlotId,
            services: index === 0 ? selectedServicePayload : [],
          }),
        ),
      );

      // ── Success: reset UI, refresh grid, show feedback banner ──
      setShowConfirmModal(false);
      setPendingBooking(null);
      clearSlots();
      setSelectedServices({});
      refresh();
      setSubmitSuccess(
        `Đặt sân thành công! ${pendingBooking.slots.length} khung giờ đã được xác nhận.`,
      );
    } catch (err) {
      logApiError("BookingField.handleConfirmBooking", err, {
        venueId,
        selectedPitchId: pendingBooking.pitchId,
        bookingDate: pendingBooking.bookingDate,
        selectedSlotCount: pendingBooking.timeSlotIds.length,
      });
      // Keep modal open so user can retry or dismiss
      setSubmitError(
        getApiErrorMessage(err, "Đặt sân thất bại. Vui lòng thử lại."),
      );
    } finally {
      setIsSubmitting(false);
    }

    // TODO: Player cancel booking
    // When backend exposes DELETE /player/bookings/{id} or PATCH /player/bookings/{id}/cancel,
    // add cancelPlayerBooking(bookingId) to bookingApi.ts and wire it here or in BookingPage.
  };

  return (
    <div className="min-h-screen bg-[#f5f7fb] px-4 py-6 dark:bg-slate-900">
      <div className="mx-auto w-full max-w-4xl space-y-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <button
            onClick={() => navigate(-1)}
            className="flex h-10 w-10 items-center justify-center rounded-full border border-gray-200 bg-white text-gray-700 hover:bg-gray-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100 dark:hover:bg-slate-700"
          >
            <ArrowLeft size={18} />
          </button>
          <div className="flex-1">
            <h1 className="text-xl font-semibold text-gray-900 dark:text-slate-100">
              Đặt sân
            </h1>
            <p className="text-sm text-gray-500 dark:text-slate-400">
              {venueAvailability?.venueName ?? "Đang tải thông tin sân"}
            </p>
          </div>
          <label className="flex items-center gap-2 text-xs font-semibold text-gray-600 dark:text-slate-300">
            <input
              type="checkbox"
              checked={autoRefresh}
              onChange={(event) => setAutoRefresh(event.target.checked)}
              className="h-4 w-4 rounded border-gray-300 text-emerald-600"
            />
            Cập nhật tự động
          </label>
        </div>

        <DateSelector selectedDate={selectedDate} onChange={setSelectedDate} />

        {venueAvailability?.pitches.length ? (
          <div className="rounded-2xl border border-gray-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-800">
            <label className="text-sm font-semibold text-gray-900 dark:text-slate-100">
              Chọn sân
            </label>
            <select
              value={selectedPitchId ?? ""}
              onChange={(event) => {
                setSelectedPitchId(Number(event.target.value));
                clearSlots();
              }}
              className="mt-2 w-full rounded-xl border border-gray-200 bg-white px-3 py-2 text-sm text-gray-700 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100"
            >
              {venueAvailability.pitches.map((pitchItem) => (
                <option key={pitchItem.pitchId} value={pitchItem.pitchId}>
                  {pitchItem.pitchName}
                </option>
              ))}
            </select>
            {lastUpdated && (
              <p className="mt-2 text-xs text-gray-400 dark:text-slate-500">
                Cập nhật lúc {format(lastUpdated, "HH:mm:ss")}
              </p>
            )}
          </div>
        ) : null}

        {loading && (
          <div className="rounded-2xl border border-dashed border-gray-200 bg-white p-6 text-center text-sm text-gray-500 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-400">
            Đang tải khung giờ...
          </div>
        )}

        {!loading && error && (
          <div className="rounded-2xl border border-rose-200 bg-rose-50 p-6 text-center text-sm text-rose-600 dark:border-rose-400/40 dark:bg-rose-500/10 dark:text-rose-200">
            {error}
          </div>
        )}

        {!loading && !error && !pitch && (
          <div className="rounded-2xl border border-dashed border-gray-200 bg-white p-6 text-center text-sm text-gray-500 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-400">
            Không tìm thấy sân phù hợp.
          </div>
        )}

        {!loading && !error && pitch && (
          <div className="space-y-4">
            <div className="rounded-2xl border border-gray-200 bg-white p-4 text-sm text-gray-600 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300">
              Đang xem:{" "}
              <span className="font-semibold text-gray-900 dark:text-slate-100">
                {pitch.pitchName}
              </span>
            </div>
            <SlotsGrid slots={slotItems} onSlotToggle={toggleSlot} />
            <ServiceSelector
              venueId={venueId}
              selectedServices={selectedServices}
              onChange={setSelectedServices}
              onServicesLoaded={setAvailableServices}
            />
          </div>
        )}

        {submitSuccess && (
          <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-700 dark:border-emerald-400/40 dark:bg-emerald-500/10 dark:text-emerald-200">
            {submitSuccess}
          </div>
        )}

        <SelectedSlotsBar
          selectedSlots={selectedSlots}
          onClear={clearSlots}
          onSubmit={handleSubmit}
          isSubmitting={isSubmitting}
          disableSubmit={!selectedPitchId || loading}
          fieldTotal={fieldTotal}
          serviceTotal={serviceTotal}
          totalPrice={fieldTotal + serviceTotal}
        />

        {showConfirmModal && pendingBooking && (
          <BookingConfirmModal
            open={showConfirmModal}
            onClose={() => setShowConfirmModal(false)}
            onConfirm={handleConfirmBooking}
            isSubmitting={isSubmitting}
            pitchName={pitch?.pitchName || ""}
            bookingDate={pendingBooking.bookingDate}
            slots={pendingBooking.slots}
            totalPrice={pendingBooking.totalPrice}
            error={submitError ?? null}
          />
        )}
      </div>
    </div>
  );
}