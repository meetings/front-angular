package gs.meetin.connector.dto;

import java.util.ArrayList;

public class SuggestionBatch extends MtnResponse {

    private String sourceContainerId;
    private String sourceContainerType;
    private String sourceContainerName;
    private String sourceIdInsideContainer;
    private String sourceName;
    private short sourceIsPrimary;
    private long timespanBeginEpoch;
    private long timespanEndEpoch;

    private ArrayList<CalendarSuggestion> suggestions;

    public SuggestionBatch(String sourceContainerName,
                           String sourceContainerType,
                           String sourceContainerId,
                           String sourceIdInsideContainer,
                           String sourceName,
                           short sourceIsPrimary,
                           long timespanBeginEpoch,
                           long timespanEndEpoch,
                           ArrayList<CalendarSuggestion> suggestions) {
        this.sourceContainerName = sourceContainerName;
        this.sourceContainerType = sourceContainerType;
        this.sourceContainerId = sourceContainerId;
        this.sourceIdInsideContainer = sourceIdInsideContainer;
        this.sourceName = sourceName;
        this.sourceIsPrimary = sourceIsPrimary;
        this.timespanBeginEpoch = timespanBeginEpoch;
        this.timespanEndEpoch = timespanEndEpoch;
        this.suggestions = suggestions;
    }

    public String getSourceName() {
        return sourceName;
    }

    public ArrayList<CalendarSuggestion> getSuggestions() {
        return suggestions;
    }
}
