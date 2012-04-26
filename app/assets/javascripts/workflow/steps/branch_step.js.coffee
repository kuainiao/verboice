#= require workflow/steps/step

onWorkflow ->
  class window.Branch extends Step
    @type = 'branch'

    constructor: (attrs) ->
      super(attrs)

      @next_id = attrs.next
      @options = ko.observableArray([])
      @new_option_command = ko.observable null

    button_class: () =>
      'ldirections'

    @add_to_steps: () ->
      workflow.add_step(new Branch)

    @initialize: (hash) ->
      branch = new Branch(hash)
      order = 0
      branch.options(new BranchOption(opt.conditions, order++, opt.next, branch) for opt in (hash.options || []))
      return branch

    to_hash: () =>
      $.extend(super,
        options: (option.to_hash() for option in @options())
      )

    default_name: () =>
      'Branches'

    commands: () =>
      (step_type.type for step_type in step_types)

    add_option: () =>
      new_step = workflow.create_step(@new_option_command(), false)
      @options.push(new BranchOption([], 1, new_step.id, @))

    option_for: (step) =>
      for option in @options()
        if option.next_id == step.id
          return option

    remove_option_with_confirm: (option) =>
      if confirm("Are you sure you want to remove this option and all its steps?")
        @remove_option(option)

    remove_option: (option) =>
      @options.remove option
      option.remove_next()

    remove_with_confirm: () =>
      name = @name?() || "this step"
      if confirm("Are you sure you want to remove #{name}?")
        @remove()

    remove: () =>
      for option in @options()
        option.remove_next()
      super()

    children: () =>
      (step for step in workflow.steps() when step.id in @children_ids())

    children_ids: () =>
      options = @options().sort((opt1, opt2) => opt1.order() - opt2.order())
      (option.next_id for option in options)

    move_option_up: (option) =>
      index = @options.indexOf option
      if index > 0
        debugger
        @options()[index] = @options()[index-1]
        @options()[index-1] = option

    move_option_down: (option) =>
      index = @options.indexOf option
      last = @options().length - 1
      if index < last
        debugger
        @options()[index] = @options()[last]
        @options()[last] = option
