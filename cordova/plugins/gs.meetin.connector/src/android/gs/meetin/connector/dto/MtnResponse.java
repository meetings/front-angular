package gs.meetin.connector.dto;

/**
 * Base class for all api models that can have errors
 */
public class MtnResponse {

    private ApiError error;

    public ApiError getError() {
        return error;
    }
}
