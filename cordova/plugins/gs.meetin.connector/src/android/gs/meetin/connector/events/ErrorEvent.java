package gs.meetin.connector.events;

public class ErrorEvent {

    private short errorCode = -1;
    private String title;
    private String message;

    public ErrorEvent(String title, String message) {
        this.title = title;
        this.message = message;
    }

    public  ErrorEvent(short errorCode, String title, String message) {
        this.errorCode = errorCode;
        this.title = title;
        this.message = message;
    }

    public short getErrorCode() {
        return errorCode;
    }

    public String getTitle() {
        return title;
    }

    public String getMessage() {
        return message;
    }
}
