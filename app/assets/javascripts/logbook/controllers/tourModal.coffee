angular.module 'Logbook'
.controller 'TourModalController', [
  '$scope'
  '$timeout'
  '$uibModalInstance'
  '$geolocation'
  'GeoCoder'
  'Tour'
  'Waypoint'
  'tour'
  'vessels'
  'drivers'
  'currentUser'
  (
    $scope, $timeout, $uibModalInstance, $geolocation,
    GeoCoder, Tour, Waypoint, tour, vessels, drivers, currentUser
  ) ->
    $timeout ->
      $scope.tour = tour
      $scope.tour.vesselId = vessels[0].id if vessels.length > 0
      $scope.waypoint = Waypoint.new({ driverId: currentUser.id })
      $scope.vessels = vessels
      $scope.drivers = drivers
      $scope.minimumMilage = 0
      $scope.laddatButton = null
      $scope.loading = false

      if !$scope.waypoint.latitude || !$scope.waypoint.longitude
        $scope.getPosition()

    $scope.getPosition = ($event) ->
      if $event
        $scope.laddaButton = Ladda.create($($event.target)[0])
        $scope.laddaButton.start()
      console.log('fetching current position...')
      $geolocation.getCurrentPosition({
        timeout: 60000
      }).then (position) ->
        console.log('current position fetched!')
        updatePosition(position.coords.latitude, position.coords.longitude)
        $scope.laddaButton.stop() if $scope.laddaButton
      , (response) ->
        displayError(response.error.message)
        $scope.laddaButton.stop() if $scope.laddaButton

    updatePosition = (lat, lng) ->
      $scope.waypoint.latitude = lat
      $scope.waypoint.longitude = lng
      GeoCoder.geocode(
        location:
          lat: lat
          lng: lng
      ).then (result) ->
        if result.length > 0
          $scope.waypoint.location = result[0].formatted_address

    $scope.save = (tour, waypoint) ->
      $scope.loading = true
      Tour.save(tour).then (savedTour) ->
        if tour.id
          $uibModalInstance.close()
        else
          waypoint.tourId = savedTour.id
          Waypoint.save(waypoint).then ->
            $uibModalInstance.close()
            $scope.loading = false
          , () ->
            $scope.loading = false
      , () ->
        $scope.loading = false

    $scope.updateMarker = (marker) ->
      updatePosition(marker.latLng.lat(), marker.latLng.lng())

    $scope.cancel = ->
      $uibModalInstance.dismiss('cancel')

    $scope.$watch 'tour.vesselId', ->
      vessel = _.find $scope.vessels, (vessel) ->
        vessel.id is $scope.tour.vesselId
      if vessel
        $scope.waypoint.milage = vessel.milage
        $scope.minimumMilage = vessel.milage
]
