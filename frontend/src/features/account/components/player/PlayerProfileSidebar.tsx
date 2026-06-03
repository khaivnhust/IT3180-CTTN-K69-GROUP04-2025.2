import { useState, useEffect } from "react";
import type { PlayerProfileInfo } from "../../types/account.types";
import { useAuthContext } from "../../../auth/hooks/useAuthContext";
import { CircleUserRound } from "lucide-react";

interface PlayerProfileSidebarProps {
  userInfo: PlayerProfileInfo;
  avatarSrc?: string;
}

export function PlayerProfileSidebar({ userInfo }: PlayerProfileSidebarProps) {
  const { user } = useAuthContext();
  const avatarUrl = user?.avatar || userInfo.avatarUrl;
  const [hasAvatarError, setHasAvatarError] = useState(false);

  useEffect(() => {
    setHasAvatarError(false);
  }, [avatarUrl]);

  return (
    <div className="flex w-[220px] shrink-0 flex-col gap-4">
      <div className="h-[190px] w-full overflow-hidden rounded-2xl bg-white flex items-center justify-center shadow-sm">
        {avatarUrl && !hasAvatarError ? (
          <img
            src={avatarUrl}
            alt="avatar"
            className="h-full w-full object-cover"
            onError={() => setHasAvatarError(true)}
          />
        ) : (
          <CircleUserRound className="h-24 w-24 text-slate-400" />
        )}
      </div>
      <div className="w-full rounded-2xl bg-white px-4 py-4 flex flex-col gap-2 shadow-sm">
        <div className="font-bold text-slate-900 text-xl truncate mb-1">
          {userInfo.username}
        </div>
        <div className="text-sm text-slate-600 truncate">{userInfo.email}</div>
        {userInfo.phoneNumber && (
          <div className="text-sm text-slate-600 truncate">
            SĐT: {userInfo.phoneNumber}
          </div>
        )}
        {userInfo.role && (
          <div className="text-xs font-semibold text-emerald-700 bg-emerald-50 border border-emerald-200 rounded px-2 py-0.5 w-fit uppercase">
            {userInfo.role}
          </div>
        )}
        {userInfo.teamId && (
          <div className="text-sm text-slate-600 truncate">
            Team ID: {userInfo.teamId}
          </div>
        )}
        {userInfo.createdAt && (
          <div className="text-sm text-slate-600 truncate">
            Tham gia: {new Date(userInfo.createdAt).toLocaleDateString("vi-VN")}
          </div>
        )}
      </div>
    </div>
  );
}
