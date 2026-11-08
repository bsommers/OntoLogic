package com.ontologic.models;

import ontologic.generated.*;
import jakarta.validation.*;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

public class ValidationBehaviorTest {

    private static Validator validator;

    @BeforeAll
    public static void setUp() {
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    @Test
    public void testAssetNullSerialNumberFailsValidation() {
        Asset asset = new Asset();
        Set<ConstraintViolation<Asset>> violations = validator.validate(asset);
        assertFalse(violations.isEmpty(), "Asset with null serial_number should have violations");
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("serial_number")));
    }

    @Test
    public void testValidAssetPassesValidation() {
        Asset asset = new Asset();
        asset.setSerial_number("SN-12345");
        Set<ConstraintViolation<Asset>> violations = validator.validate(asset);
        assertTrue(violations.isEmpty(), "Valid asset should have no violations");
    }

    @Test
    public void testGatewayMaxConnectionsConstraint() {
        Gateway gateway = new Gateway();
        gateway.setSerial_number("GW-001");
        gateway.setFirmware_ver("v1.0.0");
        gateway.setMax_connections(2); // Violates @Min(5)

        Set<ConstraintViolation<Gateway>> violations = validator.validate(gateway);
        assertFalse(violations.isEmpty());
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("max_connections")));

        gateway.setMax_connections(10); // Valid (>= 5)
        violations = validator.validate(gateway);
        assertTrue(violations.isEmpty());
    }
}
