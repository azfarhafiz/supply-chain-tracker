package com.trackandtrace.search.dto;

import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor

public class OrderSearchResultDto {
    private String orderRef;
    private String orderType;
    private String customerName;
    private String status;
    private LocalDateTime updatedAt;
}
