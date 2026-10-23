package com.trackandtrace.orders.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor

public class OrderEventDto {
    private String eventCode;
    private String eventDescription;
    private LocalDateTime eventTimestamp;
    private String location;

}
