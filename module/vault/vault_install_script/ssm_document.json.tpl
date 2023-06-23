{
  "schemaVersion": "2.2",
  "description": "Run Vault Setup",
  "parameters": {},
  "mainSteps": [
    {
      "action": "aws:runShellScript",
      "name": "runShellScript",
      "inputs": {
        "runCommand": ${run_command}
      }
    }
  ]
}