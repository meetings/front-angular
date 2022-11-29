class ContactPickerCtrl

  @$inject =
    [
      "$scope"
      "$rootScope"
      "$window"
      "$filter"
      "$log"
      "errorHandlerService"
      "contactService"
      "currentUserService"
      "deviceUtils"
    ]

  constructor: (@scope
                @rootScope
                @window
                @filter
                @log
                @errorHandlerService
                @contactService
                @currentUserService
                @deviceUtils) ->

    # ControllerAs doesn't play well with isolate scope, so copy properties manually to the right scope.
    # https://github.com/angular/angular.js/issues/7635
    @participants = @scope.participants
    @latestContacts = @scope.latestContacts
    @onAddParticipant = @scope.onAddParticipant
    @onRemoveParticipant = @scope.onRemoveParticipant

    @customVisible = false
    @customType = "phone"

    @user = @currentUserService.get()
    @userCountryId = @currentUserService.getUserPhoneCountryId(@user)

    if @deviceUtils.platform() != "web"
      @_initContactFilter()

  ############
  # PRIVATE
  ############

  _initContactFilter: ->
    @inputModel = ""

    debounceFilter = _.debounce(
      (value) =>
        return unless value?
        @findContacts(value, false)
    , 300)

    @scope.$watch(
      =>
        return @inputModel
      (value) =>

        if value? && value.length > 2
          debounceFilter(value)
        else
          @contacts = null
          debounceFilter(null)
    )

  _clear: ->
    @customName = ""
    @customPhonenumber = ""
    @customEmail = ""

    @inputModel = ""
    @contacts = null

  _onSelectFromActionSheet: (selectedIndex) =>
    # Cordova starts counting from 1
    selectedIndex--

    selectedContactField = @groupedContacts[0].allContactFields[selectedIndex].value

    if _.findIndex(@groupedContacts[0].phoneNumbers, value: selectedContactField) != -1
      @addParticipantPhone(@groupedContacts[0].name, selectedContactField)
    else
      @addParticipantEmail(@groupedContacts[0].name, selectedContactField)

    @scope.$apply()

  ############
  # PUBLIC
  ############

  hideDisabled: (tag) ->
    return !tag.scheduling_disabled

  disableCustomAdd: ->
    if @customType == "phone"
       return !@customName? || !@customPhonenumber? || @customPhonenumber == ""
    if @customType == "email"
      return !@customName? || !@customEmail? || @customEmail == ""

  showCustom: ->
    @customVisible = true

  toggleCustomType: ->
    @customType = if @customType == "email" then "phone" else "email"

  onAddTag: ->
    if @contacts?.length
      @addParticipantPhone(@contacts[0].name, @contacts[0].phoneNumbers[0].value)

  onRemoveTag: (tag) ->
    @onRemoveParticipant(participant: tag)

  addCustomParticipant: (name, number, email) ->
    if @customType == "phone"
      @addParticipantPhone( { formatted: name }, number)

    else
      @addParticipantEmail( { formatted: name }, email)

  addParticipantPhone: (name, number) ->
    @rootScope.$broadcast("focusInput")

    @_clear()

    initials = @contactService.parseInitials(name)

    @onAddParticipant({
      type: "phone"
      participant:
        name: name.formatted
        last_name: name.familyName || name.formatted
        phone: number
        initials: initials
    })

  addParticipantEmail: (name, email) ->
    @rootScope.$broadcast("focusInput")

    @_clear()

    initials = @contactService.parseInitials(name)

    @onAddParticipant({
      type: "email"
      participant:
        name: name.formatted
        last_name: name.familyName || name.formatted
        email: email
        initials: initials
    })

  pickContact: ->
    @contactService.pickContact().then(
      (contact) =>
        return unless contact.name?
        # Search for picked name
        @findContacts(contact.name.formatted, true)

      (failure) =>
        @log.error failure
        @scope.error = @errorHandlerService.handle(failure)
    )

  findContacts: (filter, showAsActionSheet) ->
    @contactService.findContacts(filter.trim()).then(
      (contacts) =>
        @log.debug "Found contacts", contacts

        # Merge contacts
        @groupedContacts = @filter('orderBy')(@contactService.groupContacts(contacts), 'name.formatted', false)

        if showAsActionSheet
          if !@groupedContacts[0].phoneNumbers?.length
            @scope.error = @errorHandlerService.handleAppError(@errorHandlerService.EMPTY_PHONE_NUMBER)
            return

          name = @groupedContacts[0].name
          phoneNumbers = if @groupedContacts[0].phoneNumbers? then @groupedContacts[0].phoneNumbers else []
          emails = if @groupedContacts[0].emails? then @groupedContacts[0].emails else []

          # if contact has only one phoneNumber or email, add it to the list,
          # else display actionSheet with all numbers
          if phoneNumbers.length + emails.length == 1
            if phoneNumbers.length == 1
              @addParticipantPhone(name, phoneNumbers[0].value)

            if emails.length == 1
              @addParticipantEmail(name, emails[0].value)

          else
            @groupedContacts[0].allContactFields = phoneNumbers.concat(emails)

            labels = []
            _.each(phoneNumbers, (phoneNumber) ->
              labels.push("#{phoneNumber.type}: #{phoneNumber.value}")
            )
            _.each(emails, (email) ->
              labels.push("#{email.type}: #{email.value}")
            )
            options = {
              title: "Found multiple numbers for contact"
              buttonLabels: labels
              androidEnableCancelButton : true
              winphoneEnableCancelButton : true
              addCancelButtonWithLabel: "Cancel"
            }

            @window.plugins.actionsheet.show(options, @_onSelectFromActionSheet)

        else
          @contacts = @groupedContacts

      (failure) =>
        @log.error "contacts error", failure
        @scope.error = @errorHandlerService.handle(failure)

    )

mtnContactPicker = angular.module "mtnContactPicker",
  [
    'contactModule'
    'errorHandler'
    'currentUserModule'
    'nativeUi'
    'mtnUtils'
  ]

# Contact list that uses cordova's contact picker plugin and autocompletng contact search for adding
# participants from phone's contact list and displays them in a tag list.
#
# Additionally there's a free input form for adding participants who are not found in user's contact list.
#
# Attributes:
#  participants       : List of participants.
#  latest-contacts     : List of latest contacts.
#  mtn-error-model    : Error model from parent controller.
#
# Usage:
#  <mtn-contact-picker participants="index.meeting.participants"
#                      latest-contact="index.latestContacts"
#                      mtn-error-model="index.error">
#  </mtn-contact-picker>
#
mtnContactPicker.directive "mtnContactPicker", ->
  restrict: 'E'
  scope:
    participants         : '='
    latestContacts       : '='
    error                : '=mtnErrorModel'
    onAddParticipant     : '&mtnOnAddParticipant'
    onRemoveParticipant  : '&mtnOnRemoveParticipant'

  templateUrl: '/views/partials/_contactPicker.html'
  controller: 'ContactPickerCtrl'
  controllerAs: 'contactPicker'
