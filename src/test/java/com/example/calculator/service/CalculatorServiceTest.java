package com.example.calculator.service;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class CalculatorServiceTest {

    private final CalculatorService service = new CalculatorService();

    @Test
    void add() {
        assertEquals(7.0, service.add(3, 4));
    }

    @Test
    void subtract() {
        assertEquals(1.0, service.subtract(4, 3));
    }

    @Test
    void multiply() {
        assertEquals(12.0, service.multiply(3, 4));
    }

    @Test
    void divide() {
        assertEquals(2.5, service.divide(5, 2));
    }

    @Test
    void divideByZeroThrows() {
        assertThrows(ArithmeticException.class, () -> service.divide(5, 0));
    }
}
