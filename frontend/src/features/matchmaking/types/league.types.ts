export type LeagueFormat = "KNOCKOUT" | "ROUND_ROBIN" | "GROUP_STAGE";
export type LeagueStatus = "OPENING" | "IN_PROGRESS" | "FINISHED" | "CANCELLED";

export interface League {
  id: number;
  name: string;
  format: LeagueFormat;
  numberOfTeams: number;
  prize: string;
  status: LeagueStatus;
  managerId: number;
  createdAt: string;
}

export interface LeagueRequest {
  name: string;
  format: LeagueFormat;
  numberOfTeams: number;
  prize: string;
  status: LeagueStatus;
}

export type RegistrationStatus = "PENDING" | "APPROVED" | "REJECTED";

export interface LeagueRegistration {
  id: number;
  leagueId: number;
  leagueName: string;
  teamId: number;
  teamName: string;
  captainId: number;
  captainName: string;
  status: RegistrationStatus;
  createdAt: string;
}
