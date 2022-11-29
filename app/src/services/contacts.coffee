contact = angular.module "contactModule", ["appConfig", "dateHelper", "mtnUtils", "errorHandler"]

contact.service "contactService", ($log, $q, appConfig, deviceready, deviceUtils, errorHandlerService) ->

  ############
  # PRIVATE
  ############

  ############
  # PUBLIC
  ############

  getPermissionAsked: ->
    try
      return JSON.parse localStorage.getItem("__contacts_permission_asked") ||
        deviceUtils.platform() != "ios"
    catch
      return undefined

  setPermissionAsked: (value) ->
    localStorage.setItem("__contacts_permission_asked", value)

  getLatestContacts: () ->
    return JSON.parse(localStorage.getItem("__latest_contacts"))

  setLatestContactsForUser: (userId, contacts) ->
    latestContacts = @getLatestContacts() || {}

    # Concat old contacts to new contacts
    userContacts =  contacts.concat(latestContacts[userId] || [])

    # Remove current user from contacts
    _.remove(userContacts, {id: userId})

    # Remove duplicates from contacts
    # userContacts = _.uniq(userContacts, 'phone')

    _.each(userContacts, (contact, i) ->
      firstIndex = _.findIndex(userContacts, phone: contact.phone)

      if firstIndex == -1
        firstIndex = _.findIndex(userContacts, email: contact.email)

      if firstIndex < i && firstIndex != -1
        userContacts[i] = null
    )

    userContacts = _.without(userContacts, null)

    # Save only 10 newest contacts
    latestContacts[userId] = userContacts.slice(0, 10)

    localStorage.setItem("__latest_contacts", JSON.stringify(latestContacts))

  parseInitials: (name) ->
    initials = ""
    firstName = name.givenName
    lastName = name.familyName
    formatted = name.formatted

    if firstName?
      initials = firstName.substr(0,1).toUpperCase()

    if lastName?
      initials += lastName.substr(0,1).toUpperCase()

    if !firstName? && !lastName && formatted?
      initials = formatted.substr(0,1).toUpperCase()

    return initials

  groupContacts: (contacts) ->
    tmpContacts = []
    _.each(contacts, (contact) ->

      # Find contact in tmpContacts array
      existingContact = _.findIndex(tmpContacts, (search) -> search.name.formatted.toUpperCase() == contact.name.formatted.toUpperCase())

      # if contact already exists, merge contacts
      if existingContact != -1
        if tmpContacts[existingContact].phoneNumbers?
          phoneNumbers = tmpContacts[existingContact].phoneNumbers.concat(contact.phoneNumbers)
        else
          phoneNumbers = contact.phoneNumbers

        if tmpContacts[existingContact].emails?
          emails = tmpContacts[existingContact].emails.concat(contact.emails)
        else
          emails = contact.emails

        # Remove null and multiple entries
        tmpContacts[existingContact].phoneNumbers = _(phoneNumbers).without(null).uniq('value').value()
        tmpContacts[existingContact].emails = _(emails).without(null).uniq('value').value()

      else
        tmpContacts.push(contact)
    )

    return tmpContacts

  formatPhone: (phone, countryCode) ->
    if _.contains(phone, "###")
      return { e164: phone, countryId: "TEST", countryName: "Test", valid: true, localFormat: phone }

    e164        = formatE164(countryCode, phone)
    countryId   = countryForE164Number(e164)
    countryName = countryCodeToName(countryId)
    valid       = isValidNumber(phone, countryId)
    localFormat = formatLocal(countryId, phone)
    internationalFormat = formatInternational(countryId, phone)

    return {
      e164:        e164
      countryId:   countryId
      countryName: countryName
      valid:       valid
      localFormat: localFormat
      internationalFormat: internationalFormat
    }

  isValidPhoneNumber: (phoneNumber, countryCode) ->
    # Validate phonenumber using current user's countrycode or automatically detected countrycode
    formattedPhone = @formatPhone(phoneNumber, countryCode)

    return formattedPhone.valid

  isUserPhoneNumber: (userPhoneNumber, phoneNumber, countryCode) ->
    formatted = @formatPhone(phoneNumber, countryCode)
    userPhoneFormatted = @formatPhone(userPhoneNumber, countryCode)

    return userPhoneFormatted.e164 == formatted.e164

  validateParticipantPhone: (participants, participant, user, userCountryId) ->
    # Check that participants phone number is valid or a debug number
    if !@isValidPhoneNumber(participant.phone, userCountryId) && !_.contains(participant.phone, "###")
      return error: errorHandlerService.handleAppError(errorHandlerService.INVALID_PHONE_NUMBER)

    # Check that given number doesn't already exist in participant list and it's not current user's number
    if @isUserPhoneNumber(user.phone, participant.phone, userCountryId)
      return error: errorHandlerService.handleAppError(errorHandlerService.USER_PHONENUMBER)

    existingParticipant = _.find(participants, (p) =>
      return @isUserPhoneNumber(p.phone, participant.phone, userCountryId)
    )

    if existingParticipant?
      return existingParticipant: existingParticipant

  validateParticipantEmail: (participants, participant, user) ->
    # Check that given email doesn't already exist in participant list and it's not current user's email
    if user.email == participant.email
      return error: errorHandlerService.handleAppError(errorHandlerService.USER_PHONENUMBER)

    existingParticipant = _.find(participants, (p) ->
      return p.email == participant.email
    )

    if existingParticipant?
      return existingParticipant: existingParticipant

  isValidParticipant: (participants, participant, type, user, userCountryId) ->
    if type == "phone"
      return @validateParticipantPhone(participants, participant, user, userCountryId)

    if type == "email"
      return @validateParticipantEmail(participants, participant, user)

  pickContact: (successCb, errorCb) ->
    deviceready.then ->
      deferred = $q.defer()

      navigator.contacts.pickContact(
        (success) -> deferred.resolve(success)
        (failure) -> deferred.reject(failure)
      )

      return deferred.promise

  findContacts: (filter) ->
    deviceready.then ->
      deferred = $q.defer()

      options               = new ContactFindOptions()
      options.filter        = filter
      options.multiple      = true
      options.desiredFields = [navigator.contacts.fieldType.name, navigator.contacts.fieldType.phoneNumbers, navigator.contacts.fieldType.emails];
      fields                = [navigator.contacts.fieldType.name];

      navigator.contacts.find(
        fields
        (success) -> deferred.resolve(success)
        (failure) -> deferred.reject(failure)
        options
      )

      return deferred.promise

  # Contact plugin does not have an initialization function.
  # IOS asks permission to access device's contacts on the first time contact plugin is used.
  # As a workaround, perform a search with a filter that should not return any results from anyone's contact list.
  init: ->
    return @findContacts("initContactPlugin1234567890")
