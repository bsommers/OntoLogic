package com.ontologic.app;

import ontologic.generated.*;
import jakarta.validation.*;
import java.util.Set;

public class Main {
    public static void main(String[] args) {
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        Validator validator = factory.getValidator();

        System.out.println("Running OntoLogic JVM validation tests...");
        // Test compilation and validation
        Asset asset = new Asset();
        System.out.println("Java POJO Classes loaded successfully.");

        Set<ConstraintViolation<Asset>> violations = validator.validate(asset);
        if (violations.isEmpty()) {
            System.out.println("Validation failed: expected constraint violation for null serial_number, but found none.");
            System.exit(1);
        } else {
            System.out.println("Validation successful: detected " + violations.size() + " expected violation(s):");
            for (ConstraintViolation<Asset> violation : violations) {
                System.out.println("  - " + violation.getPropertyPath() + ": " + violation.getMessage());
            }
        }
    }
}

