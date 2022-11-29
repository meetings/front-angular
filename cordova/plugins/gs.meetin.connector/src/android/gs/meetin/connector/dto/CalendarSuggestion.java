package gs.meetin.connector.dto;

public class CalendarSuggestion {
    long eventId;
    String title;
    long beginEpoch;
    long endEpoch;
    String description;
    String location;
    String participantList;
    String organizer;

    public CalendarSuggestion(long eventId,
                              String title,
                              long beginEpoch,
                              long endEpoch,
                              String description,
                              String location,
                              String participantList,
                              String organizer) {
        this.eventId = eventId;
        this.title = title;
        this.beginEpoch = beginEpoch;
        this.endEpoch = endEpoch;
        this.description = description;
        this.location = location;
        this.participantList = participantList;
        this.organizer = organizer;
    }

    public long getEventId() {
        return eventId;
    }

    public String getTitle() {
        return title;
    }

    public long getBeginEpoch() {
        return beginEpoch;
    }

    public long getEndEpoch() {
        return endEpoch;
    }

    public String getDescription() {
        return description;
    }

    public String getLocation() {
        return location;
    }

    public String getParticipantList() {
        return participantList;
    }

    public String getOrganizer() {
        return organizer;
    }

    @Override
    public String toString() {
        return "CalendarSuggestion{" +
                "title='" + title + '\'' +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        CalendarSuggestion that = (CalendarSuggestion) o;

        if (beginEpoch != that.beginEpoch) return false;
        if (endEpoch != that.endEpoch) return false;
        if (eventId != that.eventId) return false;
        if (description != null ? !description.equals(that.description) : that.description != null)
            return false;
        if (location != null ? !location.equals(that.location) : that.location != null)
            return false;
        if (organizer != null ? !organizer.equals(that.organizer) : that.organizer != null)
            return false;
        if (participantList != null ? !participantList.equals(that.participantList) : that.participantList != null)
            return false;
        if (title != null ? !title.equals(that.title) : that.title != null) return false;

        return true;
    }

    @Override
    public int hashCode() {
        int result = (int) (eventId ^ (eventId >>> 32));
        result = 31 * result + (title != null ? title.hashCode() : 0);
        result = 31 * result + (int) (beginEpoch ^ (beginEpoch >>> 32));
        result = 31 * result + (int) (endEpoch ^ (endEpoch >>> 32));
        result = 31 * result + (description != null ? description.hashCode() : 0);
        result = 31 * result + (location != null ? location.hashCode() : 0);
        result = 31 * result + (participantList != null ? participantList.hashCode() : 0);
        result = 31 * result + (organizer != null ? organizer.hashCode() : 0);
        return result;
    }
}
