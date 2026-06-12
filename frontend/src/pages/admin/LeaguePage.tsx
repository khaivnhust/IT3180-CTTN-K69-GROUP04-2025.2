import { useState, useEffect } from 'react';
import { LeagueManager } from "../../features/matchmaking/components/LeagueManager";
import { LeagueStanding, WeeklySchedule, TournamentBracket, calculateStandings } from "../../features/statistics";
import { mockTeams, mockRoundRobinMatches, mockKnockoutMatches } from "../../features/statistics/data/mockStatisticsData";
import { LeagueAnnouncementTab } from "../../features/matchmaking/components/LeagueAnnouncementTab";
import { getAdminLeagues } from "../../features/matchmaking/api/league.api";
import type { League } from "../../features/matchmaking/types/league.types";

export function LeaguePage() {
  const [viewMode, setViewMode] = useState<"MANAGER" | "STATS_RR" | "STATS_KO" | "ANNOUNCEMENTS">("MANAGER");
  const [leagues, setLeagues] = useState<League[]>([]);
  const [selectedLeagueId, setSelectedLeagueId] = useState<number | null>(null);

  const roundRobinStandings = calculateStandings(mockRoundRobinMatches, mockTeams);

  useEffect(() => {
    if (viewMode === "ANNOUNCEMENTS") {
      getAdminLeagues().then(setLeagues).catch(console.error);
    }
  }, [viewMode]);

  return (
    <section className="space-y-5">
      <header className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-2xl border border-white/15 bg-[#005E2E]/38 px-5 py-4">
        <div>
          <h2 className="text-xl font-semibold text-white">Quản lý Giải đấu</h2>
          <p className="mt-1 text-sm text-white/80">
            Tạo và quản lý các giải đấu tại sân bóng của bạn.
          </p>
        </div>
        <div className="flex gap-2 flex-wrap">
          <button 
            onClick={() => setViewMode("MANAGER")}
            className={`px-4 py-2 rounded text-sm font-medium transition ${viewMode === 'MANAGER' ? 'bg-white text-[#005E2E]' : 'bg-transparent text-white border border-white/30 hover:bg-white/10'}`}
          >
            Quản lý chung
          </button>
          <button 
            onClick={() => setViewMode("ANNOUNCEMENTS")}
            className={`px-4 py-2 rounded text-sm font-medium transition ${viewMode === 'ANNOUNCEMENTS' ? 'bg-white text-[#005E2E]' : 'bg-transparent text-white border border-white/30 hover:bg-white/10'}`}
          >
            Bảng tin
          </button>
          <button 
            onClick={() => setViewMode("STATS_RR")}
            className={`px-4 py-2 rounded text-sm font-medium transition ${viewMode === 'STATS_RR' ? 'bg-white text-[#005E2E]' : 'bg-transparent text-white border border-white/30 hover:bg-white/10'}`}
          >
            Thống kê (Vòng tròn)
          </button>
          <button 
            onClick={() => setViewMode("STATS_KO")}
            className={`px-4 py-2 rounded text-sm font-medium transition ${viewMode === 'STATS_KO' ? 'bg-white text-[#005E2E]' : 'bg-transparent text-white border border-white/30 hover:bg-white/10'}`}
          >
            Thống kê (Knockout)
          </button>
        </div>
      </header>
      
      {viewMode === "MANAGER" && <LeagueManager />}
      
      {viewMode === "ANNOUNCEMENTS" && (
        <div className="rounded-2xl border border-white/15 bg-[#005E2E]/32 p-5 shadow-lg">
          <div className="mb-6">
            <label className="block text-sm font-semibold text-white mb-2">Chọn giải đấu để xem/đăng thông báo:</label>
            <select
              value={selectedLeagueId || ""}
              onChange={(e) => setSelectedLeagueId(e.target.value ? Number(e.target.value) : null)}
              className="w-full max-w-md rounded-lg border border-white/20 bg-black/30 px-4 py-2.5 text-white focus:border-emerald-500 focus:outline-none focus:ring-1 focus:ring-emerald-500 [&>option]:bg-[#005E2E] [&>option]:text-white"
            >
              <option value="">-- Chọn giải đấu --</option>
              {leagues.map(l => (
                <option key={l.id} value={l.id}>{l.name}</option>
              ))}
            </select>
          </div>

          {selectedLeagueId ? (
            <LeagueAnnouncementTab leagueId={selectedLeagueId} isAdmin={true} />
          ) : (
            <div className="py-10 text-center text-white/50 border border-dashed border-white/10 rounded-xl">
              Vui lòng chọn giải đấu ở trên để tiếp tục.
            </div>
          )}
        </div>
      )}

      {viewMode === "STATS_RR" && (
        <div className="space-y-6">
          <LeagueStanding standings={roundRobinStandings} />
          <WeeklySchedule matches={mockRoundRobinMatches} teams={mockTeams} />
        </div>
      )}

      {viewMode === "STATS_KO" && (
        <div className="space-y-6">
          <TournamentBracket matches={mockKnockoutMatches} teams={mockTeams} />
        </div>
      )}
    </section>
  );
}
