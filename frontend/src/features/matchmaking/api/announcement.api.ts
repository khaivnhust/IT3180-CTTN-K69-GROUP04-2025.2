import apiClient from "../../../shared/api/apiClient";
import type { LeagueAnnouncement, CreateAnnouncementRequest } from "../types/announcement.types";

const MOCK_STORAGE_KEY = "mock_league_announcements";

const getMockAnnouncements = (): LeagueAnnouncement[] => {
  try {
    const stored = localStorage.getItem(MOCK_STORAGE_KEY);
    if (stored) return JSON.parse(stored);
  } catch (e) {
    console.error("Lỗi đọc localStorage", e);
  }
  return [];
};

const saveMockAnnouncements = (announcements: LeagueAnnouncement[]) => {
  try {
    localStorage.setItem(MOCK_STORAGE_KEY, JSON.stringify(announcements));
  } catch (e) {
    console.error("Lỗi lưu localStorage", e);
  }
};

export const announcementApi = {
  getAnnouncementsByLeague: async (leagueId: number): Promise<LeagueAnnouncement[]> => {
    try {
      // TODO: Backend chưa có API này. Cần implement Backend AnnouncementController
      const response = await apiClient.get(`/public/leagues/${leagueId}/announcements`);
      return response.data;
    } catch (error) {
      console.warn("Backend chưa implement API getAnnouncementsByLeague. Trả về mock data tạm thời.");
      const allAnnouncements = getMockAnnouncements();
      return allAnnouncements.filter(a => a.leagueId === leagueId);
    }
  },

  createAnnouncement: async (leagueId: number, data: CreateAnnouncementRequest): Promise<LeagueAnnouncement> => {
    try {
      // TODO: Backend chưa có API này. Cần implement Backend AnnouncementController
      const response = await apiClient.post(`/admin/leagues/${leagueId}/announcements`, data);
      return response.data;
    } catch (error) {
      console.warn("Backend chưa implement API createAnnouncement. Dùng mock data.");
      const newAnnouncement: LeagueAnnouncement = {
        id: Math.floor(Math.random() * 1000000),
        leagueId,
        title: data.title,
        content: data.content,
        createdAt: new Date().toISOString(),
      };

      const allAnnouncements = getMockAnnouncements();
      allAnnouncements.push(newAnnouncement);
      saveMockAnnouncements(allAnnouncements);

      return newAnnouncement;
    }
  }
};
