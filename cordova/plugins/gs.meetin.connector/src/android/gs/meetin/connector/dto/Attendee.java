package gs.meetin.connector.dto;

public class Attendee {

    private String name;
    private String email;

    public Attendee(String name, String email) {
        this.name = name;
        this.email = email;
    }

    public String toString() {
        return String.format("\"%s\" <%s>", name, email);
    }
}
