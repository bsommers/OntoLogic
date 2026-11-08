// Reasoning: Identify RobotArms violating the 6-axis requirement
MATCH (r:RobotArm)
WHERE r.axis_count <> 6
RETURN r.id AS device_id, r.axis_count AS actual, 6 AS expected, "Axiom Violation: Axis Count" AS reason;

// Reasoning: Recursive safety check
MATCH (c:Controller {active: true})
WHERE c.safety_status = false
RETURN c.id AS dangerous_controller;
