angular.module 'Timesheet'
.directive 'selectize', ['$timeout', ($timeout) ->
  restrict: 'A'
  require: '?ngModel'
  scope:
    options: '='
    ngDisabled: '='
    label: '@'
    create: '@'
    multiple: '='
    ngModel: '='
  link: (scope, element, attrs, ngModel) ->
    scope.label ?= 'name'

    createItem = (input) ->
      scope.$parent[scope.create](input, @)

    $select = element.selectize
      valueField: 'uuid'
      labelField: scope.label
      searchField: scope.label
      create: createItem if scope.create
      render:
        option_create: selectizeCreateTemplate

    selectize = $select[0].selectize;

    angular.forEach scope.options, (tag) ->
      selectize.addOption tag

    scope.$watchCollection 'options', (newTags, oldTags) ->
      $timeout ->
        if newTags isnt oldTags
          selectize.clear()
          selectize.clearOptions()

          angular.forEach newTags, (tag) ->
            selectize.addOption(tag)
        
        selectize.addItem(scope.ngModel)

    scope.$watch 'ngModel', ->
      $timeout ->
        selectize.addItem(scope.ngModel)

    scope.$watch 'ngDisabled', ->
      if element.prop('disabled')
        selectize.disable()
      else
        selectize.enable()

    selectize.on 'change', (value) ->
      $timeout ->
        ngModel.$setViewValue(value)
]
