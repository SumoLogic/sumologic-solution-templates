# Collector name exceeding 128 characters - should fail validation
# Only overrides the specific parameter being tested - sumo_collector_name exceeding length
# All other values inherited from test.tfvars
sumo_collector_name = "VeryLongCollectorNameThatExceedsTheMaximumAllowedLengthOf128CharactersAndShouldFailValidationForBeingTooLongToUseAsACollectorName"