package gs.meetin.connector.events;

import java.util.HashMap;

public abstract class Event {
    public static enum EventType {
        // Suggestion
        UPDATE_SUGGESTIONS,
        UPDATE_SUGGESTIONS_SUCCESSFUL
    }

    private EventType type;

    private HashMap<String, Boolean> booleans = new HashMap<String, Boolean>();
    private HashMap<String, Long> longs = new HashMap<String, Long>();

    public Event(EventType type) {
        this.type = type;
    }

    public EventType getType() {
        return type;
    }

    public void putBoolean(String key, boolean value) {
        booleans.put(key, value);
    }

    public boolean getBoolean(String key) {
        return booleans.get(key);
    }

    public void putLong(String key, long value) {
        longs.put(key, value);
    }

    public long getLong(String key) {
        return longs.get(key);
    }
}