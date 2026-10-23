package com.trackandtrace.orders.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor

public class CustomerOrderDto {
    private String orderRef;
    private String customerName;
    private String status;
    private LocalDate orderDate;
    private LocalDate requestedDeliveryDate;
    private String country;
    private Integer totalItems;
    private Double totalWeightKg;
}
