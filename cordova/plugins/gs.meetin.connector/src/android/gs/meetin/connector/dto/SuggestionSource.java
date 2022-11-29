package gs.meetin.connector.dto;

public class SuggestionSource {

    private String containerName;
    private String name;
    private String idInsideContainer;
    private short isPrimary;
    private long lastUpdateEpoch;

    public SuggestionSource(String name, String idInsideContainer, short isPrimary) {
        this.name = name;
        this.idInsideContainer = idInsideContainer;
        this.isPrimary = isPrimary;
    }

    public String getContainerName() {
        return containerName;
    }

    public String getName() {
        return name;
    }

    public String getIdInsideContainer() {
        return idInsideContainer;
    }

    public short getIsPrimary() {
        return isPrimary;
    }

    public long getLastUpdateEpoch() {
        return lastUpdateEpoch;
    }
}