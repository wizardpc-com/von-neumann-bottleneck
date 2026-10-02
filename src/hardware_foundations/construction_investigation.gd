extends VBoxContainer
## Optional input suggestions and bounded observations. Never runs or judges a circuit.
signal inputs_requested(values: Dictionary)
signal reset_requested

var observations: Array[String] = []
var evidence: Label
var input_samples: Array[Dictionary] = []
var output_samples: Array[String] = []

static func presets(level: StringName) -> Array[Dictionary]:
	match level:
		&"alu":
			return [{&"OP0": 0, &"OP1": 0}, {&"OP0": 1, &"OP1": 0}, {&"OP0": 0, &"OP1": 1}, {&"OP0": 1, &"OP1": 1}]
		&"ram":
			return [{&"ADDR": 0, &"DATA": 3, &"WRITE": 1}, {&"ADDR": 1, &"DATA": 12, &"WRITE": 1}, {&"ADDR": 0, &"DATA": 0, &"WRITE": 0}, {&"ADDR": 0, &"DATA": 5, &"WRITE": 1}, {&"ADDR": 1, &"DATA": 0, &"WRITE": 0}]
		&"load_store":
			return [{&"OP": 0, &"ARG": 6, &"ADDR": 0}, {&"OP": 3, &"ARG": 0, &"ADDR": 0}, {&"OP": 0, &"ARG": 2, &"ADDR": 1}, {&"OP": 3, &"ARG": 0, &"ADDR": 1}, {&"OP": 2, &"ARG": 0, &"ADDR": 0}, {&"OP": 1, &"ARG": 3, &"ADDR": 0}, {&"OP": 3, &"ARG": 0, &"ADDR": 0}, {&"OP": 2, &"ARG": 0, &"ADDR": 1}]
	return []

func configure(level: StringName, translate: Callable) -> void:
	name = "ConstructionInvestigation"
	var toggle := Button.new()
	toggle.text = translate.call(&"investigation.open")
	toggle.toggle_mode = true
	add_child(toggle)
	var body := VBoxContainer.new()
	body.visible = false
	add_child(body)
	toggle.toggled.connect(func(value: bool) -> void: body.visible = value)
	var question := Label.new()
	question.text = translate.call(StringName("investigation." + String(level)))
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(question)
	var instruction := Label.new()
	instruction.text = translate.call(&"investigation.instructions")
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(instruction)
	var choices: Array[Dictionary] = presets(level)
	var buttons := GridContainer.new()
	buttons.columns = 2 if level == &"alu" else 1
	body.add_child(buttons)
	for index: int in choices.size():
		var values: Dictionary = choices[index]
		var parts: PackedStringArray = []
		for key: StringName in values:
			parts.append("%s=%d" % [key, values[key]])
		var button := Button.new()
		button.name = "Preset%d" % index
		button.text = "%d · %s" % [index + 1, "  ".join(parts)]
		button.pressed.connect(func() -> void: inputs_requested.emit(values.duplicate(true)))
		buttons.add_child(button)
	var reset := Button.new()
	reset.text = translate.call(&"investigation.reset")
	reset.pressed.connect(func() -> void: reset_requested.emit())
	body.add_child(reset)
	evidence = Label.new()
	evidence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(evidence)
	clear_observations()

func observe(inputs: Dictionary, outputs: String) -> void:
	input_samples.append(inputs.duplicate(true))
	output_samples.append(outputs)
	if input_samples.size() > 8:
		input_samples.pop_front()
		output_samples.pop_front()
	observations.clear()
	for index: int in input_samples.size():
		var parts: PackedStringArray = []
		var keys: Array[String] = []
		for signal_name: Variant in input_samples[index]: keys.append(String(signal_name))
		keys.sort()
		for key: StringName in keys:
			if index == 0 or input_samples[index][key] != input_samples[index - 1].get(key):
				parts.append("%s=%d" % [key, input_samples[index][key]])
		# An arrow only compares executed samples; unchanged controls are omitted.
		observations.append("%d · %s → %s" % [index + 1, "  ".join(parts), output_samples[index]])
	evidence.text = "\n".join(observations)

func clear_observations() -> void:
	observations.clear()
	input_samples.clear()
	output_samples.clear()
	if evidence != null:
		evidence.text = ""
