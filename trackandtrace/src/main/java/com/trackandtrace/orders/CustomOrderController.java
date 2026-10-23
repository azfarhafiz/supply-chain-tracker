package com.trackandtrace.orders;

import com.trackandtrace.orders.dto.CustomerOrderDto;
import com.trackandtrace.orders.dto.OrderEventDto;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1")

public class CustomOrderController {

    private final CustomerOrderService customerOrderService;

    public CustomOrderController(CustomerOrderService customerOrderService) {
        this.customerOrderService = customerOrderService;
    }

    @GetMapping("/customer-orders/{ref}")
    public ResponseEntity<CustomerOrderDto> getOrderByRef (@PathVariable String ref) {
        CustomerOrderDto order = customerOrderService.getOrderByRef(ref);
        if (order == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(order);
    }

    @GetMapping("/orders/CUSTOMER/{ref}/events")
    public ResponseEntity<List<OrderEventDto>> getEventsByOrderRef(@PathVariable String ref) {
        List<OrderEventDto> result = customerOrderService.getEventsByOrderRef(ref);
        return ResponseEntity.ok(result);
    }

}
