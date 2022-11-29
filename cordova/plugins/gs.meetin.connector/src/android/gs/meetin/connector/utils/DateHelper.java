package gs.meetin.connector.utils;

import org.joda.time.DateTime;
import org.joda.time.format.DateTimeFormat;
import java.util.Locale;

public class DateHelper {

    public static DateTime today() {
        return new DateTime().withTimeAtStartOfDay();
    }

    public static String EpochToDateTimeString(long epoch) {

        Locale locale = Locale.getDefault();

        return DateTimeFormat.forStyle("SM").withLocale(locale).print(epoch * 1000);
    }
}
