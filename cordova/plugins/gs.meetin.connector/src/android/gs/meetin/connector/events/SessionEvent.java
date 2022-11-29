package gs.meetin.connector.events;

import org.apache.http.message.BasicNameValuePair;

public class SessionEvent extends Event {

    private BasicNameValuePair user;

    public SessionEvent(EventType type) {
        super(type);
    }

    public SessionEvent(EventType type, BasicNameValuePair user) {
        super(type);
        this.user = user;
    }

    public BasicNameValuePair getUser() {
        return user;
    }
}
