package com.kstn.group4.backend.team.service;

import com.kstn.group4.backend.config.security.services.UserPrincipal;
import com.kstn.group4.backend.exception.BusinessException;
import com.kstn.group4.backend.exception.ResourceNotFoundException;
import com.kstn.group4.backend.team.dto.CreateTeamRequest;
import com.kstn.group4.backend.team.dto.TeamResponse;
import com.kstn.group4.backend.team.dto.TeamStatusUpdateRequest;
import com.kstn.group4.backend.team.entity.Team;
import com.kstn.group4.backend.team.entity.TeamMember;
import com.kstn.group4.backend.team.enums.TeamMemberStatus;
import com.kstn.group4.backend.team.enums.TeamStatus;
import com.kstn.group4.backend.team.repository.TeamMemberRepository;
import com.kstn.group4.backend.team.repository.TeamRepository;
import com.kstn.group4.backend.user.entity.User;
import com.kstn.group4.backend.user.repository.UserRepository;
import com.kstn.group4.backend.match.repository.MatchRepository;
import com.kstn.group4.backend.match.entity.Match;
import com.kstn.group4.backend.activitylog.service.ActivityLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TeamService {

    private final TeamRepository teamRepository;
    private final TeamMemberRepository teamMemberRepository;
    private final UserRepository userRepository;
    private final MatchRepository matchRepository;
    private final ActivityLogService activityLogService;

    @Transactional
    public TeamResponse createTeam(UserPrincipal userPrincipal, CreateTeamRequest request) {
        User captain = userRepository.findById(userPrincipal.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng", "User"));

        if (teamRepository.findByCaptainId(captain.getId()).isPresent()) {
            throw new BusinessException("Bạn đã là đội trưởng của một đội bóng khác");
        }

        if (teamRepository.existsByName(request.getName())) {
            throw new BusinessException("Tên đội bóng đã được sử dụng");
        }

        Team team = new Team();
        team.setName(request.getName());
        team.setCaptain(captain);
        team.setDescription(request.getDescription());
        team.setStatus(TeamStatus.PENDING);
        final Team savedTeam = teamRepository.save(team);

        captain.setTeamId(savedTeam.getId());
        userRepository.save(captain);

        List<TeamMember> members = new ArrayList<>();
        // Add captain as ACTIVE member
        members.add(new TeamMember(savedTeam, captain.getEmail(), TeamMemberStatus.ACTIVE));

        // Add invited members
        if (request.getMemberEmails() != null) {
            for (String email : request.getMemberEmails()) {
                if (email != null && !email.trim().isEmpty() && !email.equalsIgnoreCase(captain.getEmail())) {
                    String trimmedEmail = email.trim();
                    var userOpt = userRepository.findByEmail(trimmedEmail);
                    if (userOpt.isPresent()) {
                        User existingUser = userOpt.get();
                        members.add(new TeamMember(savedTeam, trimmedEmail, TeamMemberStatus.INVITED));
                        existingUser.setTeamId(savedTeam.getId());
                        userRepository.save(existingUser);
                    } else {
                        members.add(new TeamMember(savedTeam, trimmedEmail, TeamMemberStatus.INVITED));
                    }
                }
            }
        }

        teamMemberRepository.saveAll(members);

        List<String> emails = members.stream()
                .map(m -> m.getId().getUserEmail())
                .collect(Collectors.toList());

        return new TeamResponse(
                team.getId(),
                team.getName(),
                captain.getId(),
                captain.getUsername(),
                team.getDescription(),
                team.getReputationScore(),
                team.getStatus(),
                null,
                team.getCreatedAt(),
                emails
        );
    }

    @Transactional(readOnly = true)
    public List<TeamResponse> getPendingTeams() {
        return mapToResponseList(teamRepository.findByStatus(TeamStatus.PENDING));
    }

    @Transactional(readOnly = true)
    public List<TeamResponse> getAllTeams() {
        return mapToResponseList(teamRepository.findAll());
    }

    private void logAdminActivity(String actionType, String targetId, String description) {
        org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        Integer adminId = null;
        String adminName = "System";
        if (auth != null && auth.getPrincipal() instanceof UserPrincipal principal) {
            adminId = principal.getId();
            adminName = principal.getAppUsername();
        }
        activityLogService.log(adminId, adminName, actionType, "TEAM", targetId, description, null, null);
    }

    @Transactional
    public TeamResponse updateTeamStatus(Long teamId, TeamStatusUpdateRequest request) {
        Team team = teamRepository.findById(teamId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đội bóng với ID: " + teamId, "Team"));

        team.setStatus(request.getStatus());
        teamRepository.save(team);

        if (request.getStatus() == TeamStatus.APPROVED) {
            User captain = team.getCaptain();
            captain.setTeamId(team.getId());
            userRepository.save(captain);
            logAdminActivity("APPROVE_TEAM", teamId.toString(), "Phê duyệt đội bóng: " + team.getName());
        }

        return mapToResponse(team);
    }

    @Transactional
    public void deleteTeam(Long teamId) {
        Team team = teamRepository.findById(teamId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đội bóng với ID: " + teamId, "Team"));

        // 1. Delete or clear matches associated with this team
        List<Match> matches = matchRepository.findByHostOrGuestTeamId(teamId);
        if (!matches.isEmpty()) {
            matchRepository.deleteAll(matches);
        }

        // 2. Clear team_id for all users belonging to this team
        List<User> members = userRepository.findByTeamId(teamId);
        for (User u : members) {
            u.setTeamId(null);
            userRepository.save(u);
        }

        // 3. Delete team members
        teamMemberRepository.deleteByTeamId(teamId);

        // 4. Delete team
        teamRepository.delete(team);

        logAdminActivity("DELETE_TEAM", teamId.toString(), "Xóa đội bóng: " + team.getName());
    }

    @Transactional
    public TeamResponse addReputation(Long teamId, Integer amount) {
        Team team = teamRepository.findById(teamId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đội bóng với ID: " + teamId, "Team"));
        team.setReputationScore(team.getReputationScore() + amount);
        teamRepository.save(team);
        logAdminActivity("ADD_TEAM_REPUTATION", teamId.toString(), "Cộng " + amount + " điểm uy tín cho đội " + team.getName());
        return mapToResponse(team);
    }

    @Transactional
    public TeamResponse deductReputation(Long teamId, Integer amount) {
        Team team = teamRepository.findById(teamId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đội bóng với ID: " + teamId, "Team"));
        team.setReputationScore(Math.max(0, team.getReputationScore() - amount));
        teamRepository.save(team);
        logAdminActivity("DEDUCT_TEAM_REPUTATION", teamId.toString(), "Trừ " + amount + " điểm uy tín của đội " + team.getName());
        return mapToResponse(team);
    }

    @Transactional
    public TeamResponse banTeam(Long teamId, Integer days) {
        Team team = teamRepository.findById(teamId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đội bóng với ID: " + teamId, "Team"));
        team.setStatus(TeamStatus.BANNED);
        team.setBannedUntil(LocalDateTime.now().plusDays(days));
        teamRepository.save(team);
        logAdminActivity("BAN_TEAM", teamId.toString(), "Cấm đội bóng: " + team.getName() + " trong " + days + " ngày");
        return mapToResponse(team);
    }

    private TeamResponse mapToResponse(Team team) {
        List<TeamMember> members = teamMemberRepository.findByTeamId(team.getId());
        List<String> memberEmails = members.stream()
                .map(m -> m.getId().getUserEmail())
                .collect(Collectors.toList());

        return new TeamResponse(
                team.getId(),
                team.getName(),
                team.getCaptain().getId(),
                team.getCaptain().getUsername(),
                team.getDescription(),
                team.getReputationScore(),
                team.getStatus(),
                team.getBannedUntil(),
                team.getCreatedAt(),
                memberEmails
        );
    }

    @Transactional(readOnly = true)
    public TeamResponse getMyTeam(UserPrincipal userPrincipal) {
        User user = userRepository.findById(userPrincipal.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng", "User"));

        if (user.getTeamId() == null) {
            return null;
        }

        Team team = teamRepository.findById(user.getTeamId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đội bóng với ID: " + user.getTeamId(), "Team"));

        return mapToResponse(team);
    }

    @Transactional(readOnly = true)
    public TeamResponse getTeamDetailsById(Long teamId) {
        Team team = teamRepository.findById(teamId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đội bóng với ID: " + teamId, "Team"));
        return mapToResponse(team);
    }

    @Transactional(readOnly = true)
    public List<TeamResponse> getApprovedTeams() {
        return mapToResponseList(teamRepository.findByStatus(TeamStatus.APPROVED));
    }

    private List<TeamResponse> mapToResponseList(List<Team> teams) {
        if (teams.isEmpty()) {
            return new ArrayList<>();
        }

        List<Long> teamIds = teams.stream().map(Team::getId).collect(Collectors.toList());
        List<TeamMember> allMembers = teamMemberRepository.findByTeamIdIn(teamIds);

        java.util.Map<Long, List<String>> membersMap = allMembers.stream()
                .collect(Collectors.groupingBy(
                        m -> m.getTeam().getId(),
                        Collectors.mapping(m -> m.getId().getUserEmail(), Collectors.toList())
                ));

        return teams.stream().map(team -> new TeamResponse(
                team.getId(),
                team.getName(),
                team.getCaptain().getId(),
                team.getCaptain().getUsername(),
                team.getDescription(),
                team.getReputationScore(),
                team.getStatus(),
                team.getBannedUntil(),
                team.getCreatedAt(),
                membersMap.getOrDefault(team.getId(), new ArrayList<>())
        )).collect(Collectors.toList());
    }
}
