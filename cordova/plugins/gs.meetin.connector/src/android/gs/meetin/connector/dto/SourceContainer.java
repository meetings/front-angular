package gs.meetin.connector.dto;

import java.util.ArrayList;

public class SourceContainer extends MtnResponse{

    private String containerName;
    private String containerType;
    private String containerId;
    private ArrayList<SuggestionSource> sources;

    public SourceContainer(String containerName, String containerType, String containerId, ArrayList<SuggestionSource> sources) {
        this.containerName = containerName;
        this.containerType = containerType;
        this.containerId = containerId;
        this.sources = sources;
    }

    public String getContainerName() {
        return containerName;
    }

    public String getContainerType() {
        return containerType;
    }

    public String getContainerId() {
        return containerId;
    }

    public ArrayList<SuggestionSource> getSources() {
        return sources;
    }
}
