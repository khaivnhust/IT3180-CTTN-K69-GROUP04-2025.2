import { zodResolver } from "@hookform/resolvers/zod";
import {
  useEffect,
  useState,
  type ChangeEvent,
  type DragEvent,
} from "react";
import { useForm } from "react-hook-form";

import { venueFormSchema } from "../schemas/pitchManagement.schema";
import type { VenueFormData } from "../types/pitchManagement.types";

interface UseVenueFormOptions {
  mode: "CREATE" | "EDIT" | null;
  existingVenue: {
    name: string;
    address: string;
    imageUrl: string | null;
  } | null;
}

export function useVenueForm({ mode, existingVenue }: UseVenueFormOptions) {
  const [isDragActive, setIsDragActive] = useState(false);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [previewName, setPreviewName] = useState<string>("");

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    formState: { errors },
  } = useForm<VenueFormData>({
    resolver: zodResolver(venueFormSchema),
    defaultValues: {
      venueName: "",
      venueAddress: "",
      venueDescription: "",
      imageFile: null,
    },
    mode: "onBlur",
  });

  // Reset form khi mode hoặc existingVenue thay đổi
  useEffect(() => {
    if (mode === "CREATE") {
      reset({
        venueName: "",
        venueAddress: "",
        venueDescription: "",
        imageFile: null,
      });
      setPreviewUrl(null);
      setPreviewName("");
    } else if (mode === "EDIT" && existingVenue) {
      reset({
        venueName: existingVenue.name,
        venueAddress: existingVenue.address,
        venueDescription: "",
        imageFile: null,
      });
      // Hiển thị ảnh cũ từ server
      setPreviewUrl(existingVenue.imageUrl);
      setPreviewName("");
    }
  }, [mode, existingVenue, reset]);

  // Cleanup object URL khi component unmount
  useEffect(() => {
    return () => {
      if (previewUrl && previewUrl.startsWith("blob:")) {
        URL.revokeObjectURL(previewUrl);
      }
    };
  }, [previewUrl]);

  const updatePreviewFromFile = (file: File | null) => {
    if (!file) {
      // Nếu đang edit, giữ ảnh cũ từ server
      if (mode === "EDIT" && existingVenue?.imageUrl) {
        setPreviewUrl(existingVenue.imageUrl);
      } else {
        setPreviewUrl(null);
      }
      setPreviewName("");
      return;
    }

    // Revoke blob URL cũ nếu có
    if (previewUrl && previewUrl.startsWith("blob:")) {
      URL.revokeObjectURL(previewUrl);
    }

    const nextPreviewUrl = URL.createObjectURL(file);
    setPreviewUrl(nextPreviewUrl);
    setPreviewName(file.name);
  };

  const handleImageChange = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0] ?? null;
    setValue("imageFile", file, {
      shouldDirty: true,
      shouldValidate: true,
    });
    updatePreviewFromFile(file);
  };

  const handleImageDrop = (event: DragEvent<HTMLLabelElement>) => {
    event.preventDefault();
    setIsDragActive(false);
    const file = event.dataTransfer.files[0] ?? null;

    if (!file) {
      return;
    }

    setValue("imageFile", file, {
      shouldDirty: true,
      shouldValidate: true,
    });
    updatePreviewFromFile(file);
  };

  const imageFileField = register("imageFile");

  return {
    register,
    handleSubmit,
    errors,
    imageFileField,
    handleImageChange,
    handleImageDrop,
    isDragActive,
    setIsDragActive,
    previewUrl,
    previewName,
  };
}
