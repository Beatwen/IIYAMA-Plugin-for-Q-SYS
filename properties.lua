table.insert(props,{
  Name   = "Uppercase Messages",
  Type   = "boolean",
  Value  = true
})
table.insert(props,{
  Name   = "Poll Rate",
  Type   = "integer",
  Min    = 1,
  Max    = 30,
  Value  = 2
})
table.insert(props,{
  Name   = "Warmup Time",
  Type   = "integer",
  Min    = 1,
  Max    = 60,
  Value  = 30
})
table.insert(props,{
  Name   = "Power Off Polling",
  Type   = "boolean",
  Value  = true
})
table.insert(props,{
  Name   = "Poll Errors",
  Type   = "boolean",
  Value  = true
})
table.insert(props,{
  Name   = "Input Count",
  Type   = "integer",
  Min    = 2,
  Max    = 36,
  Value  = 4
})
table.insert(props,{
  Name    = "Debug Print",
  Type    = "enum",
  Choices = {"None", "Tx/Rx", "Tx", "Rx", "Function Calls", "All"},
  Value   = "All"
})