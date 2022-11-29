package gs.meetin.connector;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.CalendarContract;
import android.util.Log;

import java.util.ArrayList;
import java.util.Iterator;

import org.joda.time.DateTime;

import gs.meetin.connector.dto.Attendee;
import gs.meetin.connector.dto.CalendarSuggestion;
import gs.meetin.connector.dto.SuggestionSource;
import gs.meetin.connector.utils.DateHelper;

public class CalendarManager {

    private final String TAG = this.getClass().getName();

    // Projection arrays. Creating indices for this array instead of doing
    // dynamic lookups improves performance.
    public static final String[] CALENDAR_PROJECTION = new String[] {
            CalendarContract.Calendars._ID,                           // 0
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,         // 1
            CalendarContract.Calendars.IS_PRIMARY                     // 2
    };

    public static final String[] EVENT_PROJECTION = new String[] {
            CalendarContract.Events._ID,                              // 0
            CalendarContract.Events.TITLE,                            // 1
            CalendarContract.Events.HAS_ATTENDEE_DATA,                // 2
            CalendarContract.Events.ORGANIZER,                        // 3
            CalendarContract.Events.DTSTART,                          // 4
            CalendarContract.Events.DTEND,                            // 5
            CalendarContract.Events.DESCRIPTION,                      // 6
            CalendarContract.Events.EVENT_LOCATION                    // 7
    };

    public static final String[] ATTENDEE_PROJECTION = new String[] {
            CalendarContract.Attendees._ID,                           // 0
            CalendarContract.Attendees.ATTENDEE_NAME,                 // 1
            CalendarContract.Attendees.ATTENDEE_EMAIL                 // 2
    };

    // The indices for the projection arrays above.
    private static final int PROJECTION_ID_INDEX = 0;

    // Calendar indices
    private static final int PROJECTION_DISPLAY_NAME_INDEX = 1;
    private static final int PROJECTION_IS_PRIMARY_INDEX   = 2;

    // Event indices
    private static final int PROJECTION_TITLE_INDEX         = 1;
    private static final int PROJECTION_ATTENDEE_DATA_INDEX = 2;
    private static final int PROJECTION_ORGANIZER_INDEX     = 3;
    private static final int PROJECTION_DTSTART_INDEX       = 4;
    private static final int PROJECTION_DTEND_INDEX         = 5;
    private static final int PROJECTION_DESCRIPTION_INDEX   = 6;
    private static final int PROJECTION_LOCATION_INDEX      = 7;

    // Attendee indices
    private static final int PROJECTION_ATTENDEE_NAME_INDEX  = 1;
    private static final int PROJECTION_ATTENDEE_EMAIL_INDEX = 2;

    public ArrayList<SuggestionSource> getCalendars(Context context) {
        Log.d(TAG, "Reading calendars...");

        ContentResolver cr = context.getContentResolver();
        Uri uri = CalendarContract.Calendars.CONTENT_URI;
        String selection = "(" + CalendarContract.Calendars.VISIBLE + " = 1)";

        Cursor cur = cr.query(uri, CALENDAR_PROJECTION, selection, null, null);

        Log.d(TAG, "Found "+ cur.getCount() + " calendars");

        ArrayList<SuggestionSource> sources = new ArrayList<SuggestionSource>();

        while (cur.moveToNext()) {
            String displayName = cur.getString(PROJECTION_DISPLAY_NAME_INDEX);
            short isPrimary = cur.getShort(PROJECTION_IS_PRIMARY_INDEX);

            SuggestionSource source = new SuggestionSource(displayName, displayName, isPrimary);

            sources.add(source);
        }

        cur.close();

        return sources;
    }

    public ArrayList<CalendarSuggestion> getEventsFromCalendar(Context context, String calendarName) {
        Log.d(TAG, "Reading gs.meetin.connector.events from " + calendarName);

        ContentResolver cr = context.getContentResolver();
        Uri uri = CalendarContract.Events.CONTENT_URI;
        String selection = "((" + CalendarContract.Events.VISIBLE + " = 1) AND ("
                                + CalendarContract.Events.CALENDAR_DISPLAY_NAME + " = ?) AND ("
                                + CalendarContract.Events.DTSTART + " > ?) AND ("
                                + CalendarContract.Events.DTEND + " < ?))";

        DateTime todayDateTime = DateHelper.today();
        String today = Long.toString(todayDateTime.getMillis());
        String threeMonthsFromNow = Long.toString(todayDateTime.plusMonths(3).getMillis());

        String[] selectionArgs = new String[] { calendarName, today, threeMonthsFromNow };

        Cursor cur = cr.query(uri, EVENT_PROJECTION, selection, selectionArgs, null);

        Log.d(TAG, "Found "+ cur.getCount() + "gs/meetin/connector/events");

         ArrayList<CalendarSuggestion> suggestions = new ArrayList<CalendarSuggestion>();

        while (cur.moveToNext()) {
            long evtId = cur.getLong(PROJECTION_ID_INDEX);
            String title = cur.getString(PROJECTION_TITLE_INDEX);

            long startDate = cur.getLong(PROJECTION_DTSTART_INDEX);
            long endDate = cur.getLong(PROJECTION_DTEND_INDEX);

            String description = cur.getString(PROJECTION_DESCRIPTION_INDEX);
            String location = cur.getString(PROJECTION_LOCATION_INDEX);

            String organizer = cur.getString(PROJECTION_ORGANIZER_INDEX);

            boolean hasAttendeeData = cur.getString(PROJECTION_ATTENDEE_DATA_INDEX).equals("1");
            String attendees = "";

            if(hasAttendeeData) {
                ArrayList<Attendee> attendeeList = getAttendeesForEvent(context, evtId);
                attendees = attendeeListToString(attendeeList);
            }

            CalendarSuggestion suggestion = new CalendarSuggestion(evtId,
                                                                   title,
                                                                   startDate / 1000,
                                                                   endDate / 1000,
                                                                   description,
                                                                   location,
                                                                   attendees,
                                                                   organizer);

            suggestions.add(suggestion);
        }

        cur.close();

        return suggestions;
    }

    private ArrayList<Attendee> getAttendeesForEvent(Context context, long eventId) {
        Log.d(TAG, "Reading attendees for " + eventId);

        ContentResolver cr = context.getContentResolver();
        Uri uri = CalendarContract.Attendees.CONTENT_URI;
        String selection = "(" + CalendarContract.Attendees.EVENT_ID + " = ?)";

        String[] selectionArgs = new String[] { Long.toString(eventId) };

        Cursor cur = cr.query(uri, ATTENDEE_PROJECTION, selection, selectionArgs, null);

        Log.d(TAG, "Found "+ cur.getCount() + " attendees");

        ArrayList<Attendee> attendees = new ArrayList<Attendee>();

        while (cur.moveToNext()) {
            String attendeeName = cur.getString(PROJECTION_ATTENDEE_NAME_INDEX);
            String attendeeEmail = cur.getString(PROJECTION_ATTENDEE_EMAIL_INDEX);

            Attendee attendee = new Attendee(attendeeName, attendeeEmail);

            attendees.add(attendee);
        }

        cur.close();

        return attendees;
    }

    private String attendeeListToString(ArrayList<Attendee> attendeeList) {
        StringBuilder attendees = new StringBuilder();

        for(Iterator<Attendee> i = attendeeList.iterator(); i.hasNext();) {
            attendees.append(i.next().toString());

            if(i.hasNext()) {
                attendees.append(", ");
            }
        }

        return attendees.toString();
    }
}
