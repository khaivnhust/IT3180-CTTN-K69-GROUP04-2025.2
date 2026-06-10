package com.kstn.group4.backend.notification.listener;

import com.kstn.group4.backend.booking.entity.BookingStatus;
import com.kstn.group4.backend.notification.entity.NotificationType;
import com.kstn.group4.backend.notification.event.BookingStatusChangedEvent;
import com.kstn.group4.backend.notification.event.MatchScheduleChangedEvent;
import com.kstn.group4.backend.notification.event.TeamInvitationCreatedEvent;
import com.kstn.group4.backend.notification.service.NotificationService;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashSet;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class NotificationEventListener {

    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm");
    private static final DateTimeFormatter DATE_TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy");

    private final NotificationService notificationService;

    @EventListener
    public void handleBookingStatusChanged(BookingStatusChangedEvent event) {
        if (event.getNewStatus() == BookingStatus.BOOKED) {
            notificationService.createNotification(
                    event.getRecipientId(),
                    NotificationType.BOOKING_STATUS,
                    "Don dat san da duoc duyet",
                    buildBookingMessage(event, "da duoc duyet"),
                    "BOOKING",
                    event.getBookingId().toString()
            );
            return;
        }

        if (event.getNewStatus() == BookingStatus.CANCELLED) {
            notificationService.createNotification(
                    event.getRecipientId(),
                    NotificationType.BOOKING_STATUS,
                    "Don dat san da bi huy",
                    buildBookingMessage(event, "da bi huy"),
                    "BOOKING",
                    event.getBookingId().toString()
            );
        }
    }

    @EventListener
    public void handleTeamInvitationCreated(TeamInvitationCreatedEvent event) {
        notificationService.createNotification(
                event.getRecipientId(),
                NotificationType.TEAM_INVITATION,
                "Loi moi vao doi bong",
                "Ban duoc moi vao doi " + event.getTeamName() + " boi " + event.getCaptainName() + ".",
                "TEAM",
                event.getTeamId().toString()
        );
    }

    @EventListener
    public void handleMatchScheduleChanged(MatchScheduleChangedEvent event) {
        Set<Long> teamIds = new LinkedHashSet<>(event.getTeamIds());
        String title = "CANCELLED".equals(event.getChangeType())
                ? "Lich thi dau da bi huy"
                : "Lich thi dau da cap nhat";
        String message = "Tran dau tai " + event.getVenueName()
                + " luc " + event.getMatchTime().format(DATE_TIME_FORMAT)
                + ("CANCELLED".equals(event.getChangeType()) ? " da bi huy." : " da duoc xep lich.");

        for (Long teamId : teamIds) {
            notificationService.createNotificationsForTeam(
                    teamId,
                    NotificationType.MATCH_SCHEDULE,
                    title,
                    message,
                    "MATCH",
                    event.getMatchId().toString()
            );
        }
    }

    private String buildBookingMessage(BookingStatusChangedEvent event, String statusText) {
        return "Don #" + event.getBookingId()
                + " tai " + event.getPitchName()
                + " ngay " + event.getBookingDate().format(DATE_FORMAT)
                + " luc " + event.getStartTime().format(TIME_FORMAT)
                + " " + statusText + ".";
    }
}
